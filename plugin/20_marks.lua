local pack = require("util.pack")

pack.plug(function()
  -- [=[0123456789()[]{}.<>^'"]=] ..
  local mark_names = vim.split([=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]=], "")

  local au = vim.api.nvim_create_augroup("mark_signs", { clear = true })
  local ns = vim.api.nvim_create_namespace("mark_signs")

  local iter_marks = function(buf, cb)
    local line_count = vim.api.nvim_buf_line_count(buf)
    for _, name in ipairs(mark_names) do
      local lnum = vim.api.nvim_buf_get_mark(buf, name)[1]
      if lnum > 0 and lnum <= line_count then
        cb(name, lnum)
      end
    end
  end

  vim.api.nvim_create_autocmd("MarkSet", {
    group = au,
    desc = "Remove overlapping letter marks on the same line",
    callback = function(e)
      local new_name, new_line = e.data.name, e.data.line
      if not new_name:match("%a") or new_line == 0 then
        return
      end
      iter_marks(e.buf, function(name, lnum)
        if name:match("%a") and new_line == lnum and new_name ~= name then
          vim.cmd.delmark(name)
        end
      end)
    end,
  })

  -- NOTE: After neovim#39218 (NVIM 0.12.2+), `MarkSet` also fires on deletion,
  -- so the event can be changed to `{ "BufRead", "MarkSet" }`.
  -- WARN: `MarkSet` currently only supports `[a-zA-Z]` marks.
  vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
    group = au,
    desc = "Frequently update mark signs",
    callback = function(e)
      vim.api.nvim_buf_clear_namespace(e.buf, ns, 0, -1)
      local is_normal_buf = vim.bo[e.buf].buftype == ""
      iter_marks(e.buf, function(name, lnum)
        if not is_normal_buf and not name:match("%a") then
          return
        end
        vim.api.nvim_buf_set_extmark(e.buf, ns, lnum - 1, 0, {
          sign_text = name,
          sign_hl_group = "DiagnosticHint",
        })
      end)
    end,
  })

  vim.keymap.set("n", "dm", "<Cmd>exe 'delmarks ' . getcharstr()<Enter>", { desc = "Del mark" })
end)
