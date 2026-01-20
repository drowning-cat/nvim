local pack = require("util.pack")

pack.add({
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
})

pack.now(function()
  require("render-markdown").setup({
    checkbox = { enabled = false },
    code = { sign = false, width = "full" },
    heading = { icons = {} },
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    group = vim.api.nvim_create_augroup("render_md_keymaps", { clear = true }),
    desc = "Define `render-markdown` keymaps",
    callback = function()
      vim.keymap.set("n", "\\", "<Cmd>RenderMarkdown buf_toggle<Enter>", { desc = "Toggle md preview" })
    end,
  })
end)
