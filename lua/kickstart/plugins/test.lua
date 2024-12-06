-- test.lua
--
-- Plugin for interacting with tests within neovim

return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',

    -- Adapters
    'marilari88/neotest-vitest',
    'nvim-neotest/neotest-jest',
    'nvim-neotest/neotest-go',
  },
  -- stylua: ignore
  keys = {
    {"<leader>t", "", desc = "+test"},
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run [T]est [F]ile" },
    { "<leader>tF", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run all [T]est [F]iles" },
    { "<leader>tr", function() require("neotest").run.run() end, desc = "Run [T]est nea[R]east" },
    { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run [T]est [L]ast" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle [T]est [S]ummary" },
    { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Open [T]est [O]utput" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle [T]est [O]utput panel" },
    { "<leader>tS", function() require("neotest").run.stop() end, desc = "Run [T]est [S]top" },
    { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle [T]est [W]atch" },
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
