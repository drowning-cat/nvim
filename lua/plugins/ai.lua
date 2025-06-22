return {
  {
    'supermaven-inc/supermaven-nvim',
    cmd = {
      'SupermavenStart',
      'SupermavenStop',
      'SupermavenRestart',
      'SupermavenToggle',
      'SupermavenStatus',
      'SupermavenUseFree',
      'SupermavenUsePro',
      'SupermavenLogout',
      'SupermavenShowLog',
      'SupermavenClearLog',
    },
    keys = {
      {
        '<leader>ta',
        function()
          local api = require 'supermaven-nvim.api'
          api.toggle()
          vim.notify(string.format('Supermaven is %s', api.is_running() and 'enabled' or 'disabled'))
        end,
        desc = '[T]oggle [a]i',
      },
    },
    opts = {
      -- <C-i> to accept the suggestion
    },
    config = function(_, opts)
      require('supermaven-nvim').setup(opts)
      require('supermaven-nvim.api').stop()
    end,
  },
}
