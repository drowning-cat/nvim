-- To see already installed colorschemes use `:Telescope colorscheme`

return {
  -- {
  --   'folke/tokyonight.nvim',
  --   priority = 1000,
  --   config = function()
  --     vim.cmd.colorscheme 'tokyonight-night'
  --   end,
  -- },
  -- {
  --   'rebelot/kanagawa.nvim',
  --   lazy = true,
  --   opts = {
  --     commentStyle = { italic = false },
  --     keywordStyle = { italic = false },
  --   },
  -- },

  { -- Theme manager
    'vague2k/huez.nvim',
    import = 'huez-manager.import',
    event = 'UIEnter',
    opts = {},
    -- stylua: ignore
    keys = {
      { '<leader>tt', function() require('huez.pickers').themes() end, desc = '[T]oggle [T]heme' },
      { '<leader>H', function() require('huez.pickers').themes() end, desc = '[H]uez' },
      { '<leader>Hl', function() require('huez.pickers').live() end, desc = '[H]uez [L]ive' },
      { '<leader>He', function() require('huez.pickers').ensured() end, desc = '[H]uez [E]nsured' },
      { '<leader>Hf', function() require('huez.pickers').favorites() end, desc = '[H]uez [F]avorites' },
    },
  },
}
