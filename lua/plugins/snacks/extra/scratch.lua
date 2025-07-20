---@module 'snacks'

---@class snacks.Picker
---@field [string] unknown

local M = {}

---@param opts? snacks.picker.Config
function M.pick_scratch(opts)
  return Snacks.picker.pick(vim.tbl_deep_extend('keep', opts or {}, {
    preview = function(ctx)
      local notify = ctx.picker.preview.notify
      ctx.picker.preview.notify = function(self, msg, level, nopts)
        if level == 'warn' and msg == 'empty file' then
        else
          notify(self, msg, level, nopts)
        end
      end
      return Snacks.picker.preview.file(ctx)
    end,
    finder = function(_, ctx)
      local items = {}
      local align = {}
      local def_align = function(id, val, min, max)
        align[id] = math.min(max, math.max(align[id] or min, val or min))
      end
      for _, scr in ipairs(Snacks.scratch.list()) do
        local it = {
          file = scr.file,
          title = scr.name,
          item = scr,
          text = Snacks.picker.util.text(scr, { 'name', 'branch', 'ft' }),
          branch = scr.branch and string.format('branch: %s', scr.branch) or '',
        }
        def_align('title', #it.title, 1, 10)
        def_align('branch', #it.branch, 1, 20)
        table.insert(items, it)
      end
      ctx.picker.align = align
      return items
    end,
    format = function(item, picker)
      local ret = {}
      local scr = item.item
      local icon, icon_hl = Snacks.util.icon(scr.ft, 'filetype')
      local a = Snacks.picker.util.align
      table.insert(ret, { a(icon, 3), icon_hl })
      table.insert(ret, { a(scr.name, picker.align.title, { truncate = true }) })
      table.insert(ret, { string.rep(' ', 5) })
      table.insert(ret, { a(item.branch, picker.align.branch, { truncate = true }), 'Number' })
      table.insert(ret, { string.rep(' ', 7) })
      ---@diagnostic disable-next-line: missing-fields
      vim.list_extend(ret, Snacks.picker.format.filename({ text = '', dir = true, file = scr.cwd }, picker))
      return ret
    end,
    confirm = function(picker, item)
      if item then
        local scr = item.item
        Snacks.scratch.open { file = scr.file, icon = scr.icon, name = scr.name, ft = scr.ft }
      end
      picker:close()
    end,
    actions = {
      delete = function(picker)
        local to_delete = picker:selected { fallback = true }
        for _, del in ipairs(to_delete) do
          os.remove(del.file)
        end
        picker.list:constrain_cursor()
        picker:find {
          on_done = function()
            picker.list:set_selected()
            if picker:count() == 0 then
              picker:close()
            end
          end,
        }
      end,
    },
    win = {
      input = {
        keys = {
          ['<C-d>'] = { 'delete', mode = { 'i', 'n' } },
          ['d'] = 'delete',
        },
      },
    },
  } --[[@as snacks.picker.Config]]))
end

return M
