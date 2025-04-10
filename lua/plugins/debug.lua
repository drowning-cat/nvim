return {
  'mfussenegger/nvim-dap',
  event = 'VeryLazy',
  dependencies = {
    { -- Creates a debugger User Interface
      'rcarriga/nvim-dap-ui',
      dependencies = 'nvim-neotest/nvim-nio',
      specs = {
        { 'folke/lazydev.nvim', library = { 'nvim-dap-ui' } },
      },
    },
    -- Support for .vscode/tasks.json
    { 'stevearc/overseer.nvim' },
    -- Virtual text
    { 'theHamsta/nvim-dap-virtual-text' },
    -- Bridge mason.nvim with nvim-dap
    { 'williamboman/mason.nvim', dependencies = 'jay-babu/mason-nvim-dap.nvim' },
    -- Configuration for debug adapters
    -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation?ref=tamerlan.dev#lua
    { 'jbyuki/one-small-step-for-vimkind' }, -- neovim lua
    { 'leoluz/nvim-dap-go' },
    { 'mxsdev/nvim-dap-vscode-js' },
    -- Required for parsing `launch.json`
    { 'Joakker/lua-json5', build = './install.sh' },
  },
  -- stylua: ignore
  keys = {
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
    { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Set Breakpoint' },
    { '<F5>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<F10>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<F11>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<F12>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception
    { '<F7>', function() require('dapui').toggle() end, desc = 'Debug: See last session result.' },
    { '<leader>du', function() require('dapui').toggle() end, desc = 'Debug: Toggle dap [u]i' },
    { '<leader>de', function() require('dapui').eval() end, desc = 'Debug: [e]val', mode = { 'n', 'v' } },
  },
  init = function()
    vim.g.mason_install_extend {
      'local-lua-debugger-vscode',
      'delve',
      'js-debug-adapter',
    }
  end,
  config = function()
    local dap, dapui = require 'dap', require 'dapui'

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    for type, icon in pairs {
      Breakpoint = '',
      BreakpointCondition = '',
      BreakpointRejected = '',
      LogPoint = '',
      Stopped = '',
    } do
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define('Dap' .. type, { text = icon, texthl = hl, numhl = hl })
    end

    dapui.setup { ---@diagnostic disable-line: missing-fields
      layouts = {
        {
          position = 'left',
          size = 40,
          elements = {
            { id = 'stacks', size = 0.3 },
            { id = 'breakpoints', size = 0.2 },
            { id = 'scopes', size = 0.5 },
          },
        },
      },
    }

    -- Open/Close DapUI automatically
    dap.listeners.before.attach.dapui_config = dapui.open
    dap.listeners.before.launch.dapui_config = dapui.open
    dap.listeners.before.event_terminated.dapui_config = dapui.close
    dap.listeners.before.event_exited.dapui_config = dapui.close

    local is_dapui = function()
      return vim.bo.ft == 'dap-repl' or vim.bo.ft:match '^dapui_'
    end
    vim.api.nvim_create_autocmd('QuitPre', {
      callback = function()
        if is_dapui() then
          dapui.close()
        end
      end,
    })
    vim.api.nvim_create_autocmd('BufWinEnter', {
      callback = function()
        if is_dapui() then
          vim.wo.statuscolumn = ''
          vim.b.ministatusline_disable = true
        end
      end,
    })

    -- Language configurations

    local mason_path = function(subpath)
      return vim.fn.resolve(vim.fn.stdpath 'data' .. '/mason/packages/' .. subpath)
    end

    ---> Lua

    dap.adapters.nlua = function(callback, conf)
      local adapter = {
        type = 'server',
        host = conf.host or '127.0.0.1',
        port = conf.port or 8086,
      }
      if conf.start_neovim then
        local dap_run = dap.run
        dap.run = function(c) ---@diagnostic disable-line: duplicate-set-field
          adapter.port = c.port
          adapter.host = c.host
        end
        require('osv').run_this()
        dap.run = dap_run
      end
      callback(adapter)
    end

    dap.configurations.lua = {
      {
        type = 'nlua',
        request = 'attach',
        name = 'Run this file',
        start_neovim = {},
      },
      {
        type = 'nlua',
        request = 'attach',
        name = 'Attach to running Neovim instance (port = 8086)',
        port = 8086,
      },
    }

    ---> Go

    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }

    ---> JavaScript

    require('dap-vscode-js').setup { ---@diagnostic disable-line: missing-fields
      -- node_path = 'node', -- Path of node executable. Defaults to $NODE_PATH, and then 'node'
      debugger_path = mason_path 'js-debug-adapter',
      debugger_cmd = { 'js-debug-adapter' },
      adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
    }
    for _, language in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
      dap.configurations[language] = {
        -- Debug NodeJS single file
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
        },
        -- Debug NodeJS processes (make sure to add --inspect when you run the process)
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
        },
        -- Debug Web Applications (client side)
        {
          type = 'pwa-chrome',
          request = 'launch',
          name = 'Launch & Debug Chrome',
          url = function()
            local co = coroutine.running()
            return coroutine.create(function()
              vim.ui.input({
                prompt = 'Enter URL: ',
                default = 'http://localhost:3000',
              }, function(url)
                if url == nil or url == '' then
                  return
                else
                  coroutine.resume(co, url)
                end
              end)
            end)
          end,
          webRoot = vim.fn.getcwd(),
          protocol = 'inspector',
          sourceMaps = true,
          userDataDir = false,
        },
      }
    end
  end,
}
