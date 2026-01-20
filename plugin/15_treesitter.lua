local ts_install = vim.g.ts_install or {}

local pack = require("util.pack")

pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
})

pack.now(function()
  vim.treesitter.language.register("tsx", "typescriptreact")

  local ts_filetypes = vim
    .iter(ts_install)
    :map(function(lang)
      return vim.treesitter.language.get_filetypes(lang)
    end)
    :flatten()
    :totable()

  require("nvim-treesitter").install(ts_install)

  vim.api.nvim_create_autocmd("FileType", {
    pattern = ts_filetypes,
    desc = "Setup treesitter for a buffer",
    group = vim.api.nvim_create_augroup("ts_setup", { clear = true }),
    callback = function(e)
      vim.treesitter.start(e.buf)
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      vim.wo[0][0].foldmethod = "expr"
      vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
  })

  local ts_swap = require("nvim-treesitter-textobjects.swap")
  -- stylua: ignore
  vim.keymap.set("n", "<Leader>a", function() ts_swap.swap_next("@parameter.inner") end, { desc = "Swap arg next" })
  -- stylua: ignore
  vim.keymap.set("n", "<Leader>A", function() ts_swap.swap_previous("@parameter.inner") end, { desc = "Swap arg prev" })
end)

pack.later(function()
  local ts_context = require("treesitter-context")
  ts_context.setup()
  -- stylua: ignore
  vim.keymap.set("n", "[c", function() ts_context.go_to_context(vim.v.count1) end, { desc = "Jump context" })
end)
