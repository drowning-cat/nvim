return {
  'nvim-neo-tree/neo-tree.nvim',
  cmd = 'Neotree',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  deactivate = function()
    vim.cmd [[Neotree close]]
  end,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal' },
  },
  opts = {
    sources = { 'filesystem' },
    filesystem = {
      use_libuv_file_watcher = true,
    },
    window = {
      mappings = {
        ['\\'] = 'close_window',
        ['<leftrelease>'] = 'open',
        ['l'] = 'open_nofocus',
        ['h'] = 'close_node',
        ['Y'] = {
          function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg('+', path, 'c')
          end,
          desc = '[Y]ank path to clipboard',
        },
        ['P'] = { 'toggle_preview', config = { use_float = false } },
      },
    },
    commands = {
      open_nofocus = function(state)
        require('neo-tree.sources.filesystem.commands').open(state)
        if vim.bo.ft ~= 'neo-tree' then
          vim.cmd [[Neotree focus]]
        end
      end,
    },
  },
}
