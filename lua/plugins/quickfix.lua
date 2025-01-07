vim.keymap.set('n', '[q', '<cmd>cprev<CR>', { desc = 'Goto next [q]uickfix entry' })
vim.keymap.set('n', ']q', '<cmd>cnext<CR>', { desc = 'Goto prev [q]uickfix entry' })
vim.keymap.set('n', '[Q', '<cmd>cfirst<CR>', { desc = 'Goto first [q]uickfix entry' })
vim.keymap.set('n', ']Q', '<cmd>clast<CR>', { desc = 'Goto last [q]uickfix entry' })

return {
  {
    'kevinhwang91/nvim-bqf',
    ft = 'qf',
  },
  {
    'stevearc/quicker.nvim',
    ft = 'qf',
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {
      winrestore = {
        height = true,
      },
    },
    -- stylua: ignore
    keys = {
      { '<leader>q', function() require('quicker').toggle { focus = true } end, { desc = 'Toggle [q]quickfix list' } },
      { '<leader>l', function() require('quicker').toggle { loclist = true, focus = true } end, { desc = 'Toggle [l]oclist list' } },
    },
  },
}
