return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['<leftrelease>'] = 'open',
          ['l'] = 'open_nofocus',
        },
      },
      commands = {
        open_nofocus = function(state)
          require('neo-tree.sources.filesystem.commands').open(state)
          vim.cmd [[Neotree focus]]
        end,
      },
    },
  },
}
