vim.pack.add({
  { src = "https://github.com/stevearc/quicker.nvim" },
})

local quicker = require("quicker")

local toggle_rhs = function(opts)
  opts = vim.tbl_extend("keep", opts or {}, { min_height = 10 })
  return function()
    quicker.toggle(opts)
  end
end

vim.keymap.set("n", "<leader>l", toggle_rhs(), { desc = "Toggle quickfix" })
vim.keymap.set("n", "<leader>L", toggle_rhs({ loclist = true }), { desc = "Toggle loclist" })

require("quicker").setup({
  keys = {
    {
      ">",
      function()
        quicker.expand({ before = 2, after = 2, add_to_existing = true })
      end,
      desc = "Expand quickfix context",
    },
    {
      "<",
      function()
        quicker.collapse()
      end,
      desc = "Collapse quickfix context",
    },
  },
})
