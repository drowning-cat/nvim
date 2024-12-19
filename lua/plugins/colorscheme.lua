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
      { '<leader>tt', function() require('huez.pickers').themes() end, desc = '[T]oggle [T]theme' },
      { '<leader>ttl', function() require('huez.pickers').live() end, desc = '[T]oggle [T]theme [L]ive' },
      { '<leader>tte', function() require('huez.pickers').ensured() end, desc = '[T]oggle [T]theme [E]nsured' },
      { '<leader>ttf', function() require('huez.pickers').favorites() end, desc = '[T]oggle [T]theme [F]avorite' },
    },
  },
}
