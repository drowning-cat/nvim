return {
  'saghen/blink.cmp',
  version = '*',
  build = 'cargo build --release',
  dependencies = {
    { 'rafamadriz/friendly-snippets' },
    { 'echasnovski/mini.icons' },
    { 'folke/lazydev.nvim', optional = true },
    -- Compatibility layer for `nvim-cmp` completion sources
    -- { 'saghen/blink.compat', version = '*', opts = {} },
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = 'none',

      -- Move
      ['<C-j>'] = { 'select_next', 'fallback' },
      ['<C-k>'] = { 'select_prev', 'fallback' },
      -- stylua: ignore
      ['<C-n>'] = { function(cmp) cmp.select_next { auto_insert = true } end }, -- no fallback
      -- stylua: ignore
      ['<C-p>'] = { function(cmp) cmp.select_prev { auto_insert = true } end }, -- no fallback

      -- Accept
      ['<C-y>'] = { 'select_and_accept' },
      -- stylua: ignore
      ['<C-CR>'] = { function(cmp) cmp.select_and_accept() end }, -- no fallback

      -- Show
      ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' }, -- no fallback
      -- Cancel
      ['<C-c>'] = { 'cancel', 'fallback' },
      -- Hide
      ['<C-e>'] = { 'hide' }, -- no fallback
      ['<Esc>'] = {
        function(cmp)
          cmp.hide()
          return false -- run fallback after
        end,
        'fallback',
      },

      -- Scroll
      ['<C-d>'] = { 'scroll_documentation_down' },
      ['<C-u>'] = { 'scroll_documentation_up' },

      -- Snippet
      ['<C-l>'] = { 'snippet_forward', 'fallback' },
      ['<C-h>'] = { 'snippet_backward', 'fallback' },

      cmdline = {
        ['<C-j>'] = { 'select_next' },
        ['<C-k>'] = { 'select_prev' },
        -- stylua: ignore
        ['<C-n>'] = { function(cmp) cmp.select_next { auto_insert = true } end },
        -- stylua: ignore
        ['<C-p>'] = { function(cmp) cmp.select_prev { auto_insert = true } end },
        ['<C-y>'] = {
          function(cmp)
            cmp.select_and_accept {
              callback = function()
                vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n')
              end,
            }
          end,
        },
        ['<C-c>'] = { nil }, -- No need to bind
        ['<C-e>'] = { 'hide' },
        ['<Esc>'] = { -- https://github.com/Saghen/blink.cmp/issues/547#issuecomment-2559100432
          function(cmp)
            cmp.hide()
            vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, false, true), 'n')
          end,
        },
      },
    },
    appearance = {
      kind_icons = {
        Text = '',
        Method = '',
        Function = '',
        Constructor = '',
        Field = '',
        Variable = '',
        Class = '',
        Interface = '',
        Module = '',
        Property = '',
        Unit = '',
        Value = '',
        Enum = '',
        Keyword = '',
        Snippet = '',
        Color = '',
        File = '',
        Reference = '',
        Folder = '',
        EnumMember = '',
        Constant = '',
        Struct = '',
        Event = '',
        Operator = '',
        TypeParameter = '',
      },
    },
    completion = {
      documentation = {
        auto_show = true,
      },
      accept = {
        auto_brackets = { enabled = true },
      },
      menu = {
        max_height = 15,
        draw = {
          gap = 2,
          columns = {
            { 'kind_icon' },
            { 'label', 'label_description', gap = 1 },
            { 'source_name' },
          },
          components = {
            kind_icon = {
              highlight = function(ctx)
                local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                return hl
              end,
            },
            source_name = {
              text = function(ctx)
                return '[' .. ctx.source_name .. ']'
              end,
            },
          },
        },
      },
      list = {
        selection = {
          preselect = true,
          auto_insert = false,
        },
      },
    },
    signature = { enabled = true },
    sources = {
      default = function()
        local sources = {
          'lsp',
          'path',
          'snippets',
          'buffer',
        }
        if require('lazy.core.config').plugins['lazydev.nvim'] then
          table.insert(sources, 1, 'lazydev')
        end
        return sources
      end,
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100,
        },
      },
    },
  },
  opts_extend = { 'sources.default' },
}
