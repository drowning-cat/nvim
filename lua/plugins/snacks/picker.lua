---@module 'snacks'

local extend = require('misc.util').extend

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
  sidebar = { --[[Override]]
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

---@alias CycleState {index:number,last_preset:string}

---@class snacks.Picker
---@field state { cycle?:CycleState, up_stack?:string[] }?

---@alias When fun(picker:snacks.Picker,preset:string,source:string?):boolean
---@alias What fun(picker:snacks.Picker,layout:snacks.picker.layout.Config):snacks.picker.layout.Config[]
---@alias CycleConfig { [1]: When, [2]: What }

---@type CycleConfig[]
-- stylua: ignore
local cycle_config = {
  {
    function(_, preset) return preset:match '^vertical' end,
    function(_, layout)
      local layouts = require('snacks.picker.config.layouts')
      return {
        extend(layout),
        extend(layouts.vertical),
        extend(layouts.vertical, function(ly) ly.layout[3].height = 0.7 end),
        extend(user_layouts.better_telescope, function(ly) ly.layout[2].width = 0.9 end),
        extend(user_layouts.better_telescope),
        extend(user_layouts.better_telescope, function(ly) ly.layout[2].width = 0.1 end),
      }
    end,
  },
  {
    function(_, preset) return preset:match '^ivy' end,
    function(_, layout)
      return {
        extend(layout),
        extend(layout, function(ly) ly.layout.height = 0.7 end),
      }
    end,
  },
  {
    function(_, preset) return preset:match '^better_telescope' end,
    function(_, layout)
      return {
        extend(layout),
        extend(layout, function(ly) ly.layout[2].width = 0.1 end),
        extend(layout, function(ly) ly.layout[2].width = 0.9 end),
      }
    end,
  },
}

---@param direction 'next'|'prev'
local cycle_action = function(direction)
  ---@type fun(picker:snacks.Picker, item?:snacks.picker.Item, action?:snacks.picker.Action): boolean|string?
  return function(picker, _, _)
    picker.state = vim.tbl_extend('keep', picker.state or {}, {
      cycle = { index = 1, last_preset = nil },
    })
    local layout_config = Snacks.picker.config.layout(picker.opts)
    local source = picker.init_opts.source or ''
    local preset
    if type(layout_config.preset) == 'function' then
      preset = layout_config.preset(source)
    else
      preset = layout_config.preset --[[@as string?]]
    end
    preset = preset or ''
    local config ---@type CycleConfig?
    config = vim.iter(cycle_config):find(function(conf) ---@param conf CycleConfig
      return conf[1](picker, preset, source)
    end)
    if not config then
      return
    end
    local layouts = config[2](picker, layout_config)
    local state = picker.state.cycle --[[@as CycleState]]
    if direction == 'prev' then
      state.index = state.index > 1 and state.index - 1 or #layouts
    end
    if direction == 'next' then
      state.index = state.index < #layouts and state.index + 1 or 1
    end
    state.last_preset = preset
    picker:set_layout(layouts[state.index])
  end
end

return {
  'folke/snacks.nvim',
  ---@type snacks.Config
  opts = {
    picker = {
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
        cycle_prev = cycle_action 'prev',
        cycle_next = cycle_action 'next',
        pick_win = function(picker) --[[Override]]
          if not picker.layout.split then
            picker.layout:hide()
          end
          local custom_filter = function(_, buf)
            local ft = vim.bo[buf].ft
            return ft ~= 'qf' and not ft:find '^snacks'
          end
          local win = Snacks.picker.util.pick_win { main = picker.main, filter = custom_filter }
          if not win then
            if not picker.layout.split then
              picker.layout:unhide()
            end
            return true
          end
          picker.main = win
          if not picker.layout.split then
            vim.defer_fn(function()
              if not picker.closed then
                picker.layout:unhide()
              end
            end, 100)
          end
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
            ['<M-c>'] = { 'cycle_next', mode = { 'i', 'n' } },
            ['<M-S-c>'] = { 'cycle_prev', mode = { 'i', 'n' } },
            ['<C-h>'] = { '<C-w>h', expr = true, mode = { 'i', 'n' } },
            ['<C-l>'] = { '<C-w>l', expr = true, mode = { 'i', 'n' } },
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
            ['<M-c>'] = 'cycle_next',
            ['<M-S-c>'] = 'cycle_next',
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
            ['<M-c>'] = 'cycle_next',
            ['<M-S-c>'] = 'cycle_next',
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
            require('misc.save-colors').save_colorscheme(item.text)
          end,
          on_close = function()
            if vim.g.snacks_colors_confirm ~= true then
              require('misc.save-colors').load_colorscheme()
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
          cwd = vim.u.find_root(),
          layout = {
            preset = 'sidebar',
            preview = 'main',
          },
          actions = {
            explorer_del = function(picker) --[[Override]]
              local actions = require 'snacks.explorer.actions'
              local Tree = require 'snacks.explorer.tree'
              local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected { fallback = true })
              if #paths == 0 then
                return
              end
              local trash_cmd = function(path)
                return 'trash ' .. path
              end
              local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ':p:~:.') or #paths .. ' files'
              actions.confirm('Put to the trash ' .. what .. '?', function()
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
                  local job_id = vim.fn.jobstart(trash_cmd(path), {
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
            safe_delete = function(picker)
              local is_root = vim.iter(picker:selected { fallback = true }):any(function(v)
                return not v.parent
              end)
              if not is_root then
                picker:action 'explorer_del'
              end
            end,
            explorer_up = function(picker) --[[Override]]
              picker.state = vim.tbl_extend('keep', picker.state or {}, { up_stack = {} })
              table.insert(picker.state.up_stack, picker:cwd())
              vim.api.nvim_set_current_dir(vim.fs.dirname(picker:cwd())) -- picker:set_cwd + picker:find
            end,
            explorer_down = function(picker)
              local is_root = vim.iter(picker:selected { fallback = true }):any(function(v)
                return not v.parent
              end)
              local up_stack = (picker.state or {}).up_stack
              if is_root and up_stack and #up_stack > 0 then
                vim.api.nvim_set_current_dir(table.remove(up_stack, #up_stack))
              else
                vim.api.nvim_set_current_dir(picker:dir())
              end
            end,
            confirm_pick = function(picker, item)
              if not item.dir then
                picker:action 'pick_win'
              end
              picker:action 'confirm'
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
                ['<C-up>'] = 'explorer_up',
                ['<C-down>'] = 'explorer_down',
                ['<CR>'] = { '<CR>', { 'confirm' } },
                ['<S-CR>'] = { '<S-CR>', { 'confirm', 'focus_list' } },
                ['<C-S-CR>'] = { '<C-S-CR>', { 'confirm', 'close' } },
                ['l'] = { 'l', { 'confirm' } },
                ['L'] = { 'L', { 'confirm', 'focus_list' } },
                ['<C-S-L>'] = { '<C-S-L>', { 'confirm', 'close' } },
                ['p'] = { 'p', { 'confirm_pick' } },
                ['P'] = { 'P', { 'confirm_pick', 'focus_list' } },
                ['O'] = 'explorer_open',
                ['d'] = 'safe_delete',
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
    },
  },
}
