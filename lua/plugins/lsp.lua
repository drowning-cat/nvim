return {
  { -- Neovim-lua LSP
    'folke/lazydev.nvim',
    ft = 'lua',
    dependencies = {
      'Bilal2453/luvit-meta',
    },
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },

  {
    'j-hui/fidget.nvim',
    event = 'VimEnter',
    opts = {},
  },

  { -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'saghen/blink.cmp',
    },
    init = function()
      vim.g.mason_install_extend {
        'clangd',
        'cssls',
        'emmet_ls',
        'eslint',
        'gopls',
        'html',
        'jsonls',
        'lua_ls',
        'pyright',
        'rust_analyzer',
        'tailwindcss',
        'ts_ls',
      }
    end,
    config = function()
      -- This function gets run when an LSP attaches to a particular buffer.
      --   That is to say, every time a new file is opened that is associated with
      --   an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --   function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          -- We create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
          end

          -- Rename the variable under your cursor.
          -- Most Language Servers support renaming across files, etc.
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('<leader>ra', vim.lsp.buf.code_action, '[R]un [A]ction', { 'n', 'x' })

          -- Opens a popup that displays documentation about the word under your cursor
          --   See `:help K` for why this keymap
          map('K', vim.lsp.buf.hover, 'Hover documentation')

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --   See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local hl_aug = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = hl_aug,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = hl_aug,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- Disable 'DiagnosticUnnecessary' highlight when cursor is over diagnostic
          -- https://github.com/neovim/neovim/discussions/32513
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_publishDiagnostics) then
            local diagnostic_unnecessary_aug = vim.api.nvim_create_augroup('diagnostic_unnecessary_undim', { clear = false })

            local ns = vim.api.nvim_create_namespace 'diagnostic_unnecessary_hl_override'
            vim.api.nvim_set_hl(0, 'DiagnosticUnnecessaryOverride', { fg = '#4447A3' })
            -- Disable 'DiagnosticUnnecessary'
            vim.api.nvim_set_hl(0, 'DiagnosticUnnecessary', {})

            local clear_hl = function()
              -- Clear 'DiagnosticUnnecessaryOverride' highlight
              if vim.api.nvim_buf_is_valid(event.buf) then
                vim.api.nvim_buf_clear_namespace(event.buf, ns, 0, -1)
              end
            end

            local refresh_hl = function()
              local search_diagnostics = vim.diagnostic.get(event.buf, { severity = vim.diagnostic.severity.HINT })
              if vim.tbl_isempty(search_diagnostics) then
                return
              end
              -- Clear 'DiagnosticUnnecessaryOverride'
              clear_hl()
              -- Reapply 'DiagnosticUnnecessaryOverride' in the same way as 'DiagnosticUnnecessary'
              local lnum = vim.fn.line '.' - 1
              for _, diagnostic in ipairs(search_diagnostics) do
                if diagnostic._tags and diagnostic._tags.unnecessary then
                  if lnum >= diagnostic.lnum and lnum <= diagnostic.end_lnum then
                  else
                    local start = { diagnostic.lnum, diagnostic.col }
                    local finish = { diagnostic.end_lnum, diagnostic.end_col }
                    vim.hl.range(event.buf, ns, 'DiagnosticUnnecessaryOverride', start, finish)
                  end
                end
              end
            end

            -- Undim in any mode except Normal
            vim.api.nvim_create_autocmd('ModeChanged', {
              buffer = event.buf,
              group = diagnostic_unnecessary_aug,
              callback = function()
                local mode = vim.fn.mode()
                if mode == 'c' then
                  return
                elseif mode == 'n' then
                  refresh_hl()
                else
                  clear_hl()
                end
              end,
            })

            local lastlnum = nil

            -- Refresh highlighting when the cursor moves in Normal mode
            vim.api.nvim_create_autocmd('CursorMoved', {
              buffer = event.buf,
              group = diagnostic_unnecessary_aug,
              callback = function()
                local mode = vim.fn.mode()

                if mode ~= 'n' then
                  return
                end

                -- Skip if the cursor moves horizontally but not vertically
                local lnum = vim.fn.line '.' - 1
                if lnum == lastlnum then
                  return
                end
                lastlnum = lnum

                refresh_hl()
              end,
            })
          end

          --
        end,
      })

      vim.diagnostic.config {
        virtual_text = true,
      }

      -- Change diagnostic symbols in the sign column (gutter)
      --
      -- local signs = { ERROR = '', WARN = '', INFO = '', HINT = '' }
      -- local diagnostic_signs = {}
      -- for type, icon in pairs(signs) do
      --   diagnostic_signs[vim.diagnostic.severity[type]] = icon
      -- end
      -- vim.diagnostic.config { signs = { text = diagnostic_signs } }

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, blink.cmp, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)

      --  Add any additional override configuration in the following tables:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        clangd = {},
        gopls = {},
        pyright = {},
        rust_analyzer = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        ts_ls = {},
        html = {},
        cssls = {},
        tailwindcss = {},
        lua_ls = {
          -- cmd = {...},
          -- filetypes = { ...},
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      -- Ensure the servers and tools above are installed
      --  To check the current status of installed tools and/or manually install
      --  other tools, you can run
      --    :Mason
      --
      --  You can press `g?` for help in this menu.
      require('mason').setup()

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, vim.g.mason_install or {})
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup { ---@diagnostic disable-line: missing-fields
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
}
