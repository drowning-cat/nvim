-- Colorscheme
-- To see already installed colorschemes use `:Telescope colorscheme`
--
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
      { '<leader>co', function() require('huez.pickers').themes() end, desc = '[Co]lorscheme' },
      { '<leader>col', function() require('huez.pickers').live() end, desc = '[Co]lorscheme [L]ive' },
      { '<leader>coe', function() require('huez.pickers').ensured() end, desc = '[Co]lorscheme [E]nsured' },
      { '<leader>cof', function() require('huez.pickers').favorites() end, desc = '[Co]lorscheme [F]avorites' },
    },
  },
}
