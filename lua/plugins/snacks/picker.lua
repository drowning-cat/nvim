---@module 'snacks'

local extend = require('misc.util').extend

vim.schedule(function()
  if Snacks then
    ---@class snacks.picker.list
    ---@field del_target fun(self: snacks.picker.list, opts?: {pin?: boolean, pin_select?: boolean})
    local M = require 'snacks.picker.core.list'
    ---@param opts? {pin?: boolean, pin_select?: boolean}
    function M:del_target(opts)
      opts = opts or {}
      opts = vim.tbl_extend('keep', opts, { pin = false })
      opts = vim.tbl_extend('keep', opts, { pin_select = opts.pin })
      local picker = self.picker
      local to_delete = picker:selected { fallback = true }
      local is_select = #picker.list.selected ~= 0
      local norm = vim.iter(to_delete):fold(0, function(sum, sel)
        return picker.list.cursor >= sel.idx and sum + 1 or sum
      end)
      local target = math.max(1, picker.list.cursor - norm)
      if (is_select and opts.pin_select) or (not is_select and opts.pin) then
        target = math.min(target + 1, picker.list:count() - #to_delete)
      end
      picker.list:set_target(target)
    end
  end
end)

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

local parse_picker = function(picker) ---@param picker snacks.Picker
  local layout = Snacks.picker.config.layout(picker.opts)
  local source = picker.init_opts.source or ''
  local preset
  if type(layout.preset) == 'function' then
    preset = layout.preset(source)
  else
    preset = layout.preset --[[@as string?]]
  end
  preset = preset or ''
  return layout, source, preset
end

---@param direction 'next'|'prev'
local cycle_action = function(direction)
  ---@type fun(picker:snacks.Picker, item:snacks.picker.Item, action:snacks.picker.Action): boolean|string?
  return function(picker, _, _)
    picker.state = vim.tbl_extend('keep', picker.state or {}, {
      cycle = { index = 1, last_preset = nil },
    })
    local layout, source, preset = parse_picker(picker)
    local config ---@type CycleConfig?
    config = vim.iter(cycle_config):find(function(conf) ---@param conf CycleConfig
      return conf[1](picker, preset, source)
    end)
    if not config then
      return
    end
    local layouts = config[2](picker, layout)
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

---@param picker snacks.Picker
---@param opts { on_delete: function }
local trash_put = function(picker, opts)
  opts = vim.tbl_extend('keep', opts, {
    on_delete = function() end,
  })
  local selected = picker:selected { fallback = true }
  local paths = vim.tbl_map(Snacks.picker.util.path, selected)
  if #paths == 0 then
    return
  end
  local is_windows = vim.fn.has 'win32' == 1
  local trash_cmd = function(path)
    if is_windows then
      return {
        'powershell',
        '-Command',
        string.format(
          "(New-Object -ComObject Shell.Application).Namespace((Split-Path '%s')).ParseName((Split-Path '%s' -Leaf)).InvokeVerb('delete')",
          path,
          path
        ),
      }
    else
      return { 'trash', path }
    end
  end
  local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ':p:~:.') or #paths .. ' files'
  ---@param prompt string
  ---@param fn fun()
  local confirm = function(prompt, fn)
    Snacks.picker.select({ 'Yes', 'No' }, { prompt = prompt }, function(_, idx)
      if idx == 1 then
        fn()
      end
    end)
  end
  confirm('Put to the trash ' .. what .. '?', function()
    local jobs = #paths
    local deleted = {}
    local after_all = function()
      opts.on_delete(deleted)
    end
    local after_each = function()
      jobs = jobs - 1
      if jobs == 0 then
        after_all()
      end
    end
    for i, path in ipairs(paths) do
      local err_data = {}
      local job_id = vim.fn.jobstart(trash_cmd(path), {
        detach = not is_windows,
        on_stderr = function(_, data)
          err_data[#err_data + 1] = table.concat(data, '\n')
        end,
        on_exit = function(_, code)
          if code == 0 then
            table.insert(deleted, selected[i])
            Snacks.bufdelete { file = path, force = true }
          else
            local err_msg = vim.trim(table.concat(err_data, ''))
            Snacks.notify.error('Failed to delete `' .. path .. '`:\n- ' .. err_msg)
          end
          after_each()
        end,
      })
      if job_id == 0 then
        after_each()
        Snacks.notify.error('Failed to start the job for: ' .. path)
      end
    end
  end)
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
        -- NOTE: Fix cancel action.
        -- See https://github.com/folke/snacks.nvim/discussions/1768#discussioncomment-13243591
        cancel = function(picker) --[[Override]]
          picker:norm(function()
            local main = require('snacks.picker.core.main').new { float = false, file = false, current = true }
            vim.api.nvim_set_current_win(main:get())
            picker:close()
          end)
        end,
        cycle_prev = cycle_action 'prev',
        cycle_next = cycle_action 'next',
        file_rename = function(picker, item)
          local mode = vim.fn.mode()
          Snacks.rename.rename_file {
            from = item.file,
            on_rename = function()
              local Tree = require 'snacks.explorer.tree'
              Tree:refresh(item.file)
              picker.list:set_target()
              picker:find {
                on_done = function()
                  if not mode:find '^i' then
                    picker.input:stopinsert()
                  end
                end,
              }
            end,
          }
          if vim.bo.ft == 'snacks_input' then
            vim.api.nvim_input '<Esc>T/'
          end
        end,
        file_delete = function(picker)
          trash_put(picker, {
            on_delete = function(deleted)
              local Tree = require 'snacks.explorer.tree'
              for _, it in ipairs(deleted) do
                Tree:refresh(it.file)
              end
              picker.list:set_selected()
              picker.list:set_target()
              picker:find()
            end,
          })
        end,
        pick_win = function(picker, item) --[[Override]]
          if item.dir then
            return
          end
          if not picker.layout.split then
            picker.layout:hide()
          end
          local win = Snacks.picker.util.pick_win {
            main = picker.main,
            float = false,
            filter = function(_, buf)
              local switch = {
                ['^snacks_dashboard$'] = true,
                ['^qf$'] = false,
                ['^snacks'] = false,
              }
              for pat, ret in pairs(switch) do
                if string.find(vim.bo[buf].ft, pat) then
                  return ret
                end
              end
              return true
            end,
          }
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
        select_and_prev = function(picker) --[[Override]]
          if picker.list.reverse then
            Snacks.picker.actions.select_and_next(picker)
          else
            Snacks.picker.actions.select_and_prev(picker)
          end
        end,
        select_and_next = function(picker) --[[Override]]
          if picker.list.reverse then
            Snacks.picker.actions.select_and_prev(picker)
          else
            Snacks.picker.actions.select_and_next(picker)
          end
        end,
        toggle_live_insert = function(picker)
          picker:action 'toggle_live'
          picker:focus 'input'
        end,
      },
      win = {
        input = {
          keys = {
            ['<C-y>'] = { 'confirm', mode = { 'i', 'n' } },
            ['<C-h>'] = { '<C-w>h', expr = true, mode = { 'i', 'n' } },
            ['<C-l>'] = { '<C-w>l', expr = true, mode = { 'i', 'n' } },
            ['<M-Esc>'] = { 'close', mode = { 'i', 'n' } },
            ['<C-g>'] = { 'toggle_live_insert', mode = { 'i', 'n' } },
            ['<C-_>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
            ['<C-]>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
            ['<C-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
            ['<C-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
            ['<M-S-i>'] = { 'toggle_hidden', mode = { 'i', 'n' } },
            ['<M-c>'] = { 'cycle_next', mode = { 'i', 'n' } },
            ['<M-S-c>'] = { 'cycle_prev', mode = { 'i', 'n' } },
            ['ZQ'] = 'close',
            ['<M-d>'] = false,
            ['<F1>'] = { 'inspect', mode = { 'i', 'n' } },
          },
        },
        list = {
          keys = {
            ['<M-Esc>'] = 'close',
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
            ['ZQ'] = 'close',
            ['<F1>'] = 'inspect',
          },
        },
        preview = {
          keys = {
            ['<M-Esc>'] = 'close',
            ['<C-g>'] = 'toggle_live_insert',
            ['<C-_>'] = 'list_scroll_down',
            ['<C-]>'] = 'list_scroll_up',
            ['<C-d>'] = 'preview_scroll_down',
            ['<C-u>'] = 'preview_scroll_up',
            ['<M-S-i>'] = 'toggle_hidden',
            ['<M-c>'] = 'cycle_next',
            ['<M-S-c>'] = 'cycle_next',
            ['ZQ'] = 'close',
          },
        },
      },
      ---@class snacks.picker.sources.Config
      ---@diagnostic disable-next-line: duplicate-doc-field
      ---@field [string] snacks.picker.Config|{}
      sources = extend({
        buffers = {
          win = {
            input = {
              keys = {
                ['<M-d>'] = { 'bufdelete', mode = { 'i', 'n' } },
              },
            },
          },
        },
        colorschemes = {
          finder = function()
            local item_list = require('snacks.picker.source.vim').colorschemes()
            local colors = require('misc.save_colors').get_colorscheme ''
            for i, item in ipairs(item_list) do
              if item.text == colors then
                item.current = true
                table.remove(item_list, i)
                table.insert(item_list, 1, item)
              end
            end
            return item_list
          end,
          format = function(item)
            return {
              item.current and { item.text, 'Underlined' } or { item.text },
            }
          end,
          confirm = function(picker, item)
            vim.g.snacks_colors_confirm = true
            Snacks.picker.sources.colorschemes.confirm(picker, item)
            require('misc.save_colors').save_colorscheme(item.text)
          end,
          on_close = function()
            if vim.g.snacks_colors_confirm ~= true then
              require('misc.save_colors').load_colorscheme()
            end
            vim.g.snacks_colors_confirm = nil
          end,
          on_change = function(_, item)
            if item then
              pcall(vim.cmd.colorscheme, item.text)
            end
          end,
          layout = { preset = 'sidebar', layout = { position = 'right' } },
        },
        commands = {
          actions = {
            accept = function(picker, item)
              vim.cmd(item.cmd)
              picker:close()
            end,
          },
          win = {
            input = {
              keys = {
                ['<C-y>'] = { 'accept', mode = { 'i', 'n' } },
              },
            },
          },
        },
        files = {
          exclude = { '.git', 'node_modules' },
          include = { '.env', '.env.*' },
          hidden = true,
          ignored = false,
          win = {
            input = {
              keys = {
                ['<C-r>'] = { 'file_rename', mode = { 'i', 'n' } },
                ['<C-d>'] = { 'file_delete', mode = { 'i', 'n' } },
              },
            },
            list = {
              keys = {
                ['r'] = 'file_rename',
                ['d'] = 'file_delete',
              },
            },
          },
        },
        git_pickers = { --[[New]]
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
        grep = {
          exclude = { '.git', 'node_modules' },
          include = { '.env', '.env.*' },
          hidden = true,
          ignored = false,
        },
        highlights = {
          confirm = function(picker, item)
            vim.fn.setreg(vim.v.register, item.hl_group)
            picker:close()
          end,
        },
        marks = {
          actions = {
            delmark = function(picker)
              local selected = picker:selected { fallback = true }
              local to_delete = vim
                .iter(selected)
                :map(function(it)
                  return it.label
                end)
                :join ''
              vim.api.nvim_win_call(vim.fn.win_getid(vim.fn.winnr '#'), function()
                if pcall(vim.cmd.delmark, to_delete) then
                  picker.list:del_target()
                  picker:find { -- NOTE: Should also be called inside `nvim_win_cal`
                    on_done = function()
                      picker.list:set_selected()
                      if picker:count() == 0 then
                        picker:close()
                      end
                    end,
                  }
                else
                  Snacks.notify.error(string.format('Unable to delete marks: %s', to_delete))
                end
              end)
            end,
          },
          win = {
            input = {
              keys = {
                ['<C-d>'] = { 'delmark', mode = { 'i', 'n' } },
                ['d'] = 'delmark',
              },
            },
          },
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
            preview = false, ---@diagnostic disable-line
          },
          on_show = function(picker)
            local show = false
            local gap = 1
            local clamp_width = function(value)
              return math.max(20, math.min(100, value))
            end
            --
            local position = picker.resolved_layout.layout.position
            local rel = picker.layout.root
            local update = function(win) ---@param win snacks.win
              local border = win:border_size().left + win:border_size().right
              win.opts.height = 0.8
              if position == 'left' then
                win.opts.row = vim.api.nvim_win_get_position(rel.win)[1]
                win.opts.col = vim.api.nvim_win_get_width(rel.win) + gap
                win.opts.width = clamp_width(vim.o.columns - border - win.opts.col)
              end
              if position == 'right' then
                win.opts.row = vim.api.nvim_win_get_position(rel.win)[1]
                win.opts.col = -vim.api.nvim_win_get_width(rel.win) - gap
                win.opts.width = clamp_width(vim.o.columns - border + win.opts.col)
              end
              win:update()
            end
            local preview_win = Snacks.win.new {
              relative = 'editor',
              focusable = false,
              border = 'rounded',
              backdrop = false,
              show = show,
              bo = {
                filetype = 'snacks_float_preview',
                buftype = 'nofile',
                buflisted = false,
                swapfile = false,
                undofile = false,
              },
              on_win = function(win)
                update(win)
                picker:show_preview()
              end,
            }
            rel:on('WinLeave', function()
              vim.schedule(function()
                if not picker:is_focused() then
                  picker.preview.win:close()
                end
              end)
            end)
            rel:on('WinResized', function()
              update(preview_win)
            end)
            picker.preview.win = preview_win
            picker.main = preview_win.win
          end,
          on_close = function(picker)
            picker.preview.win:close()
          end,
          actions = {
            explorer_del = function(picker) --[[Override]]
              picker:action 'file_delete'
            end,
            explorer_rename = function(picker) --[[Override]]
              picker:action 'file_rename'
            end,
            explorer_up = function(picker) --[[Override]]
              picker.up_stack = picker.up_stack or {}
              local cwd = picker:cwd()
              local parent = vim.fs.dirname(cwd)
              if cwd == parent then -- root
                return
              end
              table.insert(picker.up_stack, cwd)
              -- TIP: Same as `picker:set_cwd` & `picker:find`
              vim.api.nvim_set_current_dir(parent)
            end,
            explorer_down = function(picker, item)
              if not item.parent and not vim.tbl_isempty(picker.up_stack or {}) then
                vim.api.nvim_set_current_dir(table.remove(picker.up_stack))
              else
                picker.up_stack = {}
                vim.api.nvim_set_current_dir(picker:dir())
              end
            end,
            toggle_preview = function(picker) --[[Override]]
              picker.preview.win:toggle()
            end,
            bufadd = function(_, item)
              vim.cmd.badd(item.file)
            end,
            confirm_nofocus = function(picker, item)
              if item.dir then
                picker:action 'confirm'
              else
                picker:action 'bufadd'
              end
            end,
            confirm_pick = function(picker, item)
              if not item.dir then
                picker:action 'pick_win'
              end
              picker:action 'confirm'
            end,
            copy_path = function(_, item)
              local modify = vim.fn.fnamemodify
              local filepath = item.file
              local filename = modify(filepath, ':t')
              local values = {
                filepath,
                modify(filepath, ':.'),
                modify(filepath, ':~'),
                filename,
                modify(filename, ':r'),
                modify(filename, ':e'),
              }
              local items = {
                'Absolute path: ' .. values[1],
                'Path relative to CWD: ' .. values[2],
                'Path relative to HOME: ' .. values[3],
                'Filename: ' .. values[4],
              }
              if vim.fn.isdirectory(filepath) == 0 then
                vim.list_extend(items, {
                  'Filename without extension: ' .. values[5],
                  'Extension of the filename: ' .. values[6],
                })
              end
              Snacks.picker.select(items, { prompt = 'Choose to copy to clipboard:' }, function(choice, i)
                if not choice then
                  vim.notify 'Selection cancelled'
                  return
                end
                if not i then
                  vim.notify 'Invalid selection'
                  return
                end
                local result = values[i]
                vim.fn.setreg('*', result)
                vim.notify('Copied: ' .. result)
              end)
            end,
            dir_toggle = function(picker, item)
              local actions = require 'snacks.explorer.actions'
              local Tree = require 'snacks.explorer.tree'
              if item.dir then
                Tree:toggle(item.file)
                actions.update(picker, { target = item.file, refresh = true })
              end
            end,
            safe_delete = function(picker)
              local is_root = vim.iter(picker:selected { fallback = true }):any(function(v)
                return not v.parent
              end)
              if not is_root then
                picker:action 'explorer_del'
              end
            end,
          },
          win = {
            input = {
              keys = {
                ['h'] = 'focus_list',
                ['j'] = 'focus_list',
                ['<C-r>'] = { 'explorer_rename', mode = { 'i', 'n' } },
                ['<C-d>'] = { 'explorer_del', mode = { 'i', 'n' } },
                ['<C-y>'] = { 'copy_path', mode = { 'i', 'n' } },
              },
            },
            list = {
              keys = {
                ['<Left>'] = 'dir_toggle',
                ['<Right>'] = { '<Right>', { 'confirm', 'focus_list' } },
                ['<C-Up>'] = 'explorer_up',
                ['<C-Down>'] = 'explorer_down',
                ['<CR>'] = 'confirm',
                ['<C-CR>'] = { '<C-CR>', { 'confirm', 'focus_list' } },
                ['<C-S-CR>'] = { '<C-S-CR>', { 'confirm', 'close' } },
                ['<C-S-L>'] = { '<C-S-L>', { 'confirm', 'close' } },
                ['d'] = 'safe_delete',
                ['J'] = 'list_down',
                ['K'] = 'list_up',
                ['h'] = 'dir_toggle',
                ['l'] = 'confirm',
                ['L'] = 'confirm_nofocus',
                ['o'] = { 'o', { 'confirm_pick' } },
                ['O'] = { 'O', { 'confirm_pick', 'focus_list' } },
                ['<C-o>'] = 'explorer_open',
                ['Y'] = 'copy_path',
                ['<C-y>'] = { 'copy_path', mode = { 'i', 'n' } },
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
