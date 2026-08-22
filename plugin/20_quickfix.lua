local pack = require("util.pack")

pack.add({
  { src = "https://github.com/stevearc/quicker.nvim" },
})

pack.plug(function()
  local quicker = require("quicker")

  quicker.setup({
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

  local toggle_qf = function(opts)
    quicker.toggle(vim.tbl_extend("keep", opts or {}, { min_height = 10 }))
  end
  -- stylua: ignore start
  vim.keymap.set("n", "<Leader>l", function() toggle_qf() end, { desc = "Toggle quickfix" })
  vim.keymap.set("n", "<Leader>L", function() toggle_qf({ loclist = true }) end, { desc = "Toggle loclist" })
end)
