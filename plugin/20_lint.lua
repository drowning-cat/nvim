local pack = require("util.pack")

local linters_by_ft = vim.nonnil(vim.g.linters_by_ft, {})

pack.add({
  { src = "https://github.com/mfussenegger/nvim-lint" },
})

pack.plug(function()
  local au_lint = vim.api.nvim_create_augroup("config/lint", { clear = true })

  local lint = require("lint")
  lint.linters_by_ft = vim.tbl_extend("force", lint.linters_by_ft, linters_by_ft)

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = au_lint,
    desc = "Run linting on buffer events",
    callback = function(e)
      local buf = e.buf
      if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].modifiable then
        return
      end
      if e.event == "InsertLeave" and vim.bo[buf].ft == "bigfile" then
        return
      end
      lint.try_lint()
    end,
  })
end)
