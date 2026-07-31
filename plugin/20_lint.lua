local pack = require("util.pack")

local linters_by_ft = vim.nonnil(vim.g.linters_by_ft, {})

pack.add({
  { src = "https://github.com/mfussenegger/nvim-lint" },
})

pack.plug(function()
  local lint = require("lint")

  lint.linters_by_ft = vim.tbl_extend("force", lint.linters_by_ft, linters_by_ft)

  local au_lint = vim.api.nvim_create_augroup("lint", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = au_lint,
    desc = "Run linting on buffer events",
    callback = function()
      if vim.bo.modifiable then
        lint.try_lint()
      end
    end,
  })
end)
