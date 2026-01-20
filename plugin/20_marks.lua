local pack = require("util.pack")

pack.now(function()
  local mark_names = vim.split("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", "") -- .><^

  local au = vim.api.nvim_create_augroup("mark_signs", { clear = true })
  local ns = vim.api.nvim_create_namespace("mark_signs")

  vim.api.nvim_create_autocmd({ "BufRead", "MarkSet" }, {
    group = au,
    desc = "Draw mark signs",
    callback = function(e)
      if e.event == "MarkSet" and not vim.tbl_contains(mark_names, e.match) then
        return
      end
      local line_count = vim.api.nvim_buf_line_count(e.buf)
      local mark_list = {}
      for _, name in ipairs(mark_names) do
        local mark = vim.api.nvim_mark_get(name, { buf = e.buf, timestamp = true })
        if mark.line > 0 and mark.line <= line_count then
          table.insert(mark_list, mark)
        end
      end
      table.sort(mark_list, function(a, b)
        return a.timestamp < b.timestamp
      end)
      vim.api.nvim_buf_clear_namespace(e.buf, ns, 0, -1)
      for _, mark in ipairs(mark_list) do
        vim.api.nvim_buf_set_extmark(e.buf, ns, mark.line - 1, 0, {
          sign_text = mark.name,
          sign_hl_group = "DiagnosticHint",
        })
      end
    end,
  })

  vim.keymap.set("n", "dm", "<Cmd>exe 'delmarks ' . getcharstr()<Enter>", { desc = "Del mark" })
end)
