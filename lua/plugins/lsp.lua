return {
  { -- Neovim-lua LSP
    'folke/lazydev.nvim',
    ft = 'lua',
    dependencies = {
      'Bilal2453/luvit-meta',
    },
    opts_extend = { 'library' },
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        'nvim-dap-ui',
      },
    },
  },

  { 'j-hui/fidget.nvim', event = 'VimEnter', opts = {} },

  { -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
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
      -- This function gets run when an LSP attaches to a particular buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
        callback = function(event)
          local buf_map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
          end

          buf_map('<leader>rn', vim.lsp.buf.rename, '[R]un re[n]ame')
          buf_map('<leader>ra', vim.lsp.buf.code_action, '[R]un [A]ction', { 'n', 'x' })

          -- Opens a popup that displays documentation about the word under your cursor
          --   See `:help K` for why this keymap
          buf_map('K', vim.lsp.buf.hover, 'Hover documentation')
          buf_map('<C-K>', vim.diagnostic.open_float, 'Hover diagnostic')

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          if client and client:supports_method 'textDocument/documentHighlight' then
            local group = vim.api.nvim_create_augroup('lsp_highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = group,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp_detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = group, buffer = event2.buf }
              end,
            })
          end

          -- Undim code block on hover (remove hl-DiagnosticUnnecessary)
          -- https://github.com/neovim/neovim/discussions/32513
          if client then
            local ns_id = vim.api.nvim_create_namespace(string.format('nvim.vim.lsp.%s.%d.diagnostic.underline', client.name, client.id))
            local undim_diagnostic = function(diagnostic) ---@param diagnostic vim.Diagnostic
              local extmarks = vim.api.nvim_buf_get_extmarks(
                event.buf,
                ns_id,
                { diagnostic.lnum, diagnostic.col },
                { diagnostic.end_lnum, diagnostic.end_col },
                {}
              )
              for _, extm in ipairs(extmarks) do
                vim.api.nvim_buf_del_extmark(event.buf, ns_id, extm[1])
              end
            end
            local clear_hl = function()
              pcall(vim.api.nvim_buf_clear_namespace, event.buf, ns_id, 0, -1)
            end
            local refresh_hl = function()
              clear_hl()
              --
              local lnum, col = vim.fn.line '.' - 1, vim.fn.col '.' - 1
              local line_diagnostics = {} ---@type vim.Diagnostic[]
              local search_diagnostics = vim.diagnostic.get(event.buf, { severity = vim.diagnostic.severity.HINT })
              for _, diagnostic in ipairs(search_diagnostics) do
                if diagnostic._tags and diagnostic._tags.unnecessary then
                  vim.api.nvim_buf_set_extmark(event.buf, ns_id, diagnostic.lnum, diagnostic.col, {
                    hl_group = 'DiagnosticUnnecessary',
                    end_line = diagnostic.end_lnum,
                    end_col = diagnostic.end_col,
                    strict = false,
                  })
                  if lnum >= diagnostic.lnum and lnum <= diagnostic.end_lnum then
                    table.insert(line_diagnostics, diagnostic)
                  end
                end
              end
              for _, diagnostic in ipairs(line_diagnostics) do
                if diagnostic.lnum == diagnostic.end_lnum then
                  if col <= diagnostic.col then
                    undim_diagnostic(diagnostic)
                  end
                else
                  undim_diagnostic(diagnostic)
                end
              end
            end

            local group = vim.api.nvim_create_augroup('diagnostic_unnecessary_event_group', { clear = false })

            vim.api.nvim_create_autocmd('ModeChanged', {
              buffer = event.buf,
              group = group,
              callback = function()
                local mode = vim.fn.mode()
                if mode == 'n' then
                  refresh_hl()
                elseif mode == 'c' then
                else
                  clear_hl()
                end
              end,
            })
            vim.api.nvim_create_autocmd('DiagnosticChanged', {
              buffer = event.buf,
              group = group,
              callback = function()
                if vim.fn.mode() == 'n' then
                  refresh_hl()
                end
              end,
            })
            vim.api.nvim_create_autocmd('CursorHold', {
              buffer = event.buf,
              group = group,
              callback = refresh_hl,
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

      --  Add any additional override configuration in the following tables:
      --   For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings
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

      require('mason').setup()

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
