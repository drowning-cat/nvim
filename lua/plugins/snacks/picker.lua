---@module 'snacks'

local M = {}

---@generic T
---@param from `T`
---@param fn fun(ref: T): T?
local extend = function(from, fn)
  local ref = vim.deepcopy(from)
  return fn(ref) or ref
end

---@type table<string, snacks.picker.layout.Config>
local user_layouts = {
  better_telescope = {
    reverse = true,
    layout = {
      box = 'horizontal',
      width = 0.9,
      height = 0.9,
      backdrop = false,
      {
        box = 'vertical',
        border = 'single',
        title = '{title} {live} {flags}',
        { win = 'list', border = 'none' },
        { win = 'input', height = 1, border = 'top' },
      },
      { win = 'preview', width = 0.5, border = 'single', title = '{preview}' },
    },
  },
  floating_sidebar = {
    cycle = true,
    layout = {
      box = 'horizontal',
      position = 'float',
      height = 0.95,
      width = 0,
      border = 'rounded',
      {
        box = 'vertical',
        width = 40,
        min_width = 40,
        { win = 'input', height = 1, title = '{title} {live} {flags}', border = 'single' },
        { win = 'list' },
      },
      { win = 'preview', width = 0, border = 'left' },
    },
  },
  netrw = {
    layout = {
      box = 'vertical',
      position = 'float',
      {
        win = 'input',
        border = 'single',
        height = 1,
        title = '{title} {live} {flags}',
      },
      {
        box = 'horizontal',
        height = 0.9,
        { win = 'list' },
        { win = 'preview', width = 0.6, border = 'left' },
      },
    },
  },
  sidebar = { -- [[Override]]
    auto_hide = { 'preview' },
    layout = {
      backdrop = false,
      width = 40,
      min_width = 40,
      height = 0,
      position = 'left',
      border = 'none',
      box = 'vertical',
      {
        win = 'input',
        height = 1,
        border = 'single',
        title = '{title} {live} {flags}',
        title_pos = 'center',
      },
      { win = 'list', border = 'none' },
      { win = 'preview', title = '{preview}', height = 0.4, border = 'top' },
    },
  },
  vertical_mini = {
    auto_hide = { 'preview' },
    layout = {
      backdrop = false,
      width = 0.45,
      min_width = 70,
      height = 0.55,
      min_height = 20,
      box = 'vertical',
      border = 'rounded',
      title = '{title} {live} {flags}',
      title_pos = 'center',
      { win = 'input', height = 1, border = 'bottom' },
      { win = 'list', border = 'none' },
      { win = 'preview', title = '{preview}', height = 0.4, border = 'top' },
    },
  },
}

user_layouts.better_telescope_alt = extend(user_layouts.better_telescope, function(ly)
  ly.layout[2].width = 0.6
end)

---@table <string, string|fun(source: string):string>
local presets = {
  better_telescope = function()
    return vim.o.columns >= 120 and 'better_telescope' or 'vertical'
  end,
  better_telescope_alt = function()
    return vim.o.columns >= 120 and 'better_telescope_alt' or 'vertical'
  end,
}

---@class CycleLayout
---@field index number
---@field layouts fun(self: table, picker: snacks.Picker, layout: snacks.picker.layout.Config): snacks.picker.layout.Config[]?

---@type table<string, CycleLayout>
local cycle_layouts = {
  ['^vertical'] = {
    index = 1,
    layouts = function(_, picker, layout)
      if not picker.preview.win.enabled then ---@diagnostic disable-line: undefined-field
        return
      end
      -- stylua: ignore
      return {
        layout,
        extend(layout, function(ly) ly.layout[3].height = 0.7 end)
      }
    end,
  },
  ['^ivy'] = {
    index = 1,
    layouts = function(_, _, layout)
      -- stylua: ignore
      return {
        layout,
        extend(layout, function(ly) ly.layout.height = 0.7 end),
      }
    end,
  },
  ['^better_telescope'] = {
    index = 1,
    layouts = function(_, _, layout)
      -- stylua: ignore
      return {
        layout,
        extend(layout, function(ly) ly.layout[2].width = 0.1 end),
        extend(layout, function(ly) ly.layout[2].width = 0.9 end),
      }
    end,
  },
}

---@type snacks.picker.Config
M.config = {
  layouts = user_layouts,
  layout = {
    preset = presets.better_telescope,
  },
  previewers = {
    git = {
      builtin = false,
    },
  },
  actions = {
    toggle_live_insert = function(picker)
      picker:action 'toggle_live'
      picker:focus 'input'
    end,
    cycle_layouts = function(picker)
      local layout_config = Snacks.picker.config.layout(picker.opts)
      local source = picker.init_opts.source or ''
      local preset = layout_config.preset --[[@as string]]
      if type(preset) == 'function' then
        preset = layout_config.preset(source)
      end
      local config = nil
      for match, conf in pairs(cycle_layouts) do
        if string.match(preset, match) then
          config = conf
          break
        end
      end
      if not config then
        return
      end
      local layouts = config.layouts(config, picker, layout_config)
      if not layouts then
        return
      end
      config.index = config.index + 1
      config.index = config.index > #layouts and 1 or config.index
      picker:set_layout(layouts[config.index])
      picker.opts.on_close = extend(picker.opts.on_close, function(on_close)
        return function(...)
          config.index = 1
          -- stylua: ignore
          if on_close then on_close(...) end
        end
      end)
    end,
  },
  win = {
    input = {
      keys = {
        ['<C-y>'] = { 'confirm', mode = { 'n', 'i' } },
        ['<C-g>'] = { 'toggle_live_insert', mode = { 'i', 'n' } },
        ['<C-_>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
        ['<C-]>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
        ['<C-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
        ['<C-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
        ['H'] = 'edit_split',
        ['V'] = 'edit_vsplit',
        ['<M-S-i>'] = { 'toggle_hidden', mode = { 'i', 'n' } },
        ['<M-c>'] = { 'cycle_layouts', mode = { 'i', 'n' } },
      },
    },
    list = {
      keys = {
        ['<C-g>'] = 'toggle_live_insert',
        ['<C-_>'] = 'list_scroll_down',
        ['<C-]>'] = 'list_scroll_up',
        ['<C-d>'] = 'preview_scroll_down',
        ['<C-u>'] = 'preview_scroll_up',
        ['H'] = 'edit_split',
        ['V'] = 'edit_vsplit',
        ['<M-S-i>'] = 'toggle_hidden',
        ['<M-c>'] = 'cycle_layouts',
      },
    },
    preview = {
      keys = {
        ['<C-g>'] = 'toggle_live_insert',
        ['<C-_>'] = 'list_scroll_down',
        ['<C-]>'] = 'list_scroll_up',
        ['<C-d>'] = 'preview_scroll_down',
        ['<C-u>'] = 'preview_scroll_up',
        ['H'] = 'edit_split',
        ['V'] = 'edit_vsplit',
        ['<M-S-i>'] = 'toggle_hidden',
        ['<M-c>'] = 'cycle_layouts',
      },
    },
  },
  ---@class snacks.picker.sources.Config
  ---@diagnostic disable-next-line: duplicate-doc-field
  ---@field [string] snacks.picker.Config|{}
  sources = extend({
    colorschemes = {
      confirm = function(picker, item)
        vim.g.snacks_colors_confirm = true
        Snacks.picker.sources.colorschemes.confirm(picker, item)
        require('custom.save-colors').save_colorscheme(item.text)
      end,
      on_close = function()
        if vim.g.snacks_colors_confirm ~= true then
          require('custom.save-colors').load_colorscheme()
        end
        vim.g.snacks_colors_confirm = nil
      end,
      on_change = function(_, item)
        if item then
          pcall(vim.cmd.colorscheme, item.text)
        end
      end,
      layout = { preset = 'sidebar' },
    },
    files = {
      exclude = { '.git', 'node_modules' },
      include = { '.env', '.env.*' },
      hidden = true,
      ignored = false,
    },
    grep = {
      exclude = { '.git', 'node_modules' },
      include = { '.env', '.env.*' },
      hidden = true,
      ignored = false,
    },
    --
    git_pickers = {
      finder = 'meta_pickers',
      title = 'Select Git Picker',
      format = 'text',
      search = 'git_',
      transform = function(item, ctx)
        return item.text ~= 'git_all' --
          and string.match(item.text, ctx.filter.search) ~= nil
      end,
      confirm = function(...)
        Snacks.picker.sources.pickers.confirm(...)
      end,
    },
    lsp_pickers = {
      finder = 'meta_pickers',
      title = 'Select LSP Picker',
      format = 'text',
      search = 'lsp_',
      transform = function(item, ctx)
        return item.text ~= 'lsp_all' --
          and string.match(item.text, ctx.filter.search) ~= nil
      end,
      confirm = function(...)
        Snacks.picker.sources.pickers.confirm(...)
      end,
    },
    explorer = {
      exclude = { '.git' },
      hidden = true,
      ignored = true,
      layout = {
        preset = 'sidebar',
        preview = 'main',
      },
      actions = {
        explorer_del = function(picker) -- [[Override]]
          local actions = require 'snacks.explorer.actions'
          local Tree = require 'snacks.explorer.tree'
          local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected { fallback = true })
          if #paths == 0 then
            return
          end
          local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ':p:~:.') or #paths .. ' files'
          actions.confirm('Delete ' .. what .. '?', function()
            local jobs = #paths
            local after_job = function()
              jobs = jobs - 1
              if jobs == 0 then
                picker.list:set_selected()
                actions.update(picker)
              end
            end
            for _, path in ipairs(paths) do
              local err_data = {}
              local job_id = vim.fn.jobstart('trash ' .. path, {
                detach = true,
                on_stderr = function(_, data)
                  err_data[#err_data + 1] = table.concat(data, '\n')
                end,
                on_exit = function(_, code)
                  pcall(function()
                    if code == 0 then
                      Snacks.bufdelete { file = path, force = true }
                    else
                      local err_msg = vim.trim(table.concat(err_data, ''))
                      Snacks.notify.error('Failed to delete `' .. path .. '`:\n- ' .. err_msg)
                    end
                    Tree:refresh(vim.fs.dirname(path))
                  end)
                  after_job()
                end,
              })
              if job_id == 0 then
                after_job()
                Snacks.notify.error('Failed to start the job for: ' .. path)
              end
            end
          end)
        end,
        root_safe_delete = function(picker)
          local selected = picker:selected { fallback = true }
          local has_root = vim.iter(selected):any(function(v)
            return not v.parent
          end)
          if not has_root then
            picker:action 'explorer_del'
          end
        end,
      },
      win = {
        input = {
          keys = {
            ['h'] = 'focus_list',
            ['j'] = 'focus_list',
          },
        },
        list = {
          keys = {
            ['l'] = { 'l', { 'confirm', 'focus_list' } },
            ['L'] = { 'L', { 'confirm', 'close' } },
            ['o'] = { 'o', { 'pick_win', 'jump' } },
            ['O'] = 'explorer_open',
            ['d'] = 'root_safe_delete',
          },
        },
      },
    },
  } --[[@as snacks.picker.sources.Config]], function(sources)
    for _, name in ipairs {
      'buffers',
      'cliphist',
      'commands',
      'files',
      'git_pickers',
      'git_diff',
      'git_status',
      'help',
      'highlights',
      'lsp_pickers',
      'lsp_symbols',
      'pickers',
      'picker_actions',
      'picker_format',
      'picker_layouts',
      'picker_preview',
      'projects',
      'recent',
      'treesitter',
      'undo',
      'zoxide',
    } do
      sources[name] = vim.tbl_extend('keep', sources[name] or {}, {
        layout = {
          preset = presets.better_telescope_alt,
        },
      })
    end
  end),
}

return M
