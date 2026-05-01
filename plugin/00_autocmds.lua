vim.api.nvim_create_autocmd({ "TextYankPost", "TextPutPost" }, {
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  desc = "Highlight yanking text",
  callback = function()
    vim.hl.hl_op()
  end,
})
