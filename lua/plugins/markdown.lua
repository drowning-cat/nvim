return {
  {
    'toppair/peek.nvim',
    cmd = { 'Mdopen', 'Mdclose' },
    build = 'deno task --quiet build:fast',
    config = function()
      local peek = require 'peek'
      peek.setup()
      vim.api.nvim_create_user_command('Mdopen', peek.open, {})
      vim.api.nvim_create_user_command('Mdclose', peek.close, {})
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.nvim',
    },
    opts = {
      enabled = false,
      code = {
        sign = false,
        width = 'block',
        right_pad = 1,
      },
      heading = {
        sign = false,
        icons = {},
      },
      checkbox = {
        enabled = false,
      },
    },
    config = function(_, opts)
      require('render-markdown').setup(opts)
      if Snacks then ---@module 'snacks'
        Snacks.toggle({
          name = '[m]arkdown',
          get = function()
            return require('render-markdown.state').enabled
          end,
          set = function(enabled)
            require('render-markdown')[enabled and 'enable' or 'disable']()
          end,
        }):map '<leader>tm'
      end
    end,
  },
}
