vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  desc = "Highlight yanking text",
  callback = function()
    vim.hl.on_yank()
  end,
})
