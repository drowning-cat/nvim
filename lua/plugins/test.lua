return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',

    -- Adapters:
    'marilari88/neotest-vitest',
    'nvim-neotest/neotest-jest',
    'nvim-neotest/neotest-go',
  },
  -- stylua: ignore
  keys = {
    { '<leader>T', '', desc = '+Test'},
    { '<leader>Tf', function() require('neotest').run.run(vim.fn.expand('%')) end, desc = 'Run [T]est [f]ile' },
    { '<leader>TF', function() require('neotest').run.run(vim.uv.cwd()) end, desc = 'Run all [T]est [F]iles' },
    { '<leader>Tr', function() require('neotest').run.run() end, desc = 'Run [T]est nea[r]east' },
    { '<leader>Tl', function() require('neotest').run.run_last() end, desc = 'Run [T]est [l]ast' },
    { '<leader>Ts', function() require('neotest').summary.toggle() end, desc = 'Toggle [T]est [s]ummary' },
    { '<leader>To', function() require('neotest').output.open({ enter = true, auto_close = true }) end, desc = 'Open [T]est [o]utput' },
    { '<leader>TO', function() require('neotest').output_panel.toggle() end, desc = 'Toggle [T]est [O]utput panel' },
    { '<leader>TS', function() require('neotest').run.stop() end, desc = 'Run [T]est [S]top' },
    { '<leader>Tw', function() require('neotest').watch.toggle(vim.fn.expand("%")) end, desc = 'Toggle [T]est [w]atch' },
  },
  config = function()
    require('neotest').setup { ---@diagnostic disable-line: missing-fields
      adapters = {
        require 'neotest-vitest',
        require 'neotest-jest' {
          -- jestCommand = 'npm test --',
          -- jestConfigFile = 'custom.jest.config.ts',
          -- env = { CI = true },
          -- cwd = function()
          --   return vim.fn.getcwd()
          -- end,
        },
        require 'neotest-go',
      },
    }
  end,
}
