vim.api.nvim_create_autocmd({ "TextYankPost", "TextPutPost" }, {
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  desc = "Highlight yanking text",
  callback = function()
    vim.hl.hl_op()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  group = vim.api.nvim_create_augroup("help_keymaps", { clear = true }),
  desc = "Adjust mouse keymaps in `help` buffers",
  callback = function(e)
    local buf_map = function(modes, lhs, rhs, opts) ---@param opts? vim.keymap.set.Opts
      opts = opts or {}
      opts.buf = e.buf
      vim.keymap.set(modes, lhs, rhs, opts)
    end
    buf_map("n", "<2-LeftMouse>", "viw", { desc = "Select word" })
    buf_map("n", "<C-LeftMouse>", "<LeftMouse><C-]>", { remap = true, desc = "Jump tag" })
  end,
})
