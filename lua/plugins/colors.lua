return {
  {
    'folke/tokyonight.nvim',
    config = function(_, opts)
      require('tokyonight').setup(opts)
      vim.cmd.colorscheme 'tokyonight'
    end,
  },

  -- require('misc.save_colors').lazy_setup {
  --   { 'folke/tokyonight.nvim' },
  --   { 'RRethy/base16-nvim' },
  --   { 'rebelot/kanagawa.nvim', opts = {
  --     commentStyle = { italic = false },
  --     keywordStyle = { italic = false },
  --   } },
  --   { 'rose-pine/neovim', name = 'rose-pine', opts = { styles = { italic = false } } },
  --   { 'EdenEast/nightfox.nvim' },
  -- },

  { -- Highlight todo, notes, etc in comments
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  { -- Highlight colors in code
    'brenoprata10/nvim-highlight-colors',
    event = 'VeryLazy',
    opts = {
      ---@usage 'background'|'foreground'|'virtual'
      render = 'virtual',
      ---@usage 'inline'|'eol'|'eow'
      virtual_symbol_position = 'eow',
      virtual_symbol = '⚈',
      virtual_symbol_prefix = ' ',
      virtual_symbol_suffix = '',
    },
    -- stylua: ignore
    keys = {
      { '<leader>tc', function() require('nvim-highlight-colors').toggle() end, desc = '[T]oggle [C]colors' },
    },
  },
}
