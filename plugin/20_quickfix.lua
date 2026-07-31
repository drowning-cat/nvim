vim.pack.add({
  { src = "https://github.com/stevearc/quicker.nvim" },
})

local quicker = require("quicker")

local toggle_qf = function(opts)
  quicker.toggle(vim.tbl_extend("keep", opts or {}, { min_height = 10 }))
end
-- stylua: ignore start
vim.keymap.set("n", "=q", function() toggle_qf() end, { desc = "Toggle quickfix" })
vim.keymap.set("n", "=Q", function() toggle_qf({ loclist = true }) end, { desc = "Toggle loclist" })
-- stylua: ignore end

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
