return {
  'saghen/blink.cmp',
  dependencies = {
    { 'rafamadriz/friendly-snippets' },
    { 'saghen/blink.compat', optional = true, opts = {}, version = '*' },
    { 'echasnovski/mini.icons' },
  },
  version = '*',
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = 'none',

      ['<C-n>'] = { 'select_next', 'fallback' },
      ['<C-p>'] = { 'select_prev', 'fallback' },
      ['<C-j>'] = { 'select_next', 'fallback' },
      ['<C-k>'] = { 'select_prev', 'fallback' },

      ['<C-]>'] = { 'scroll_documentation_down', 'fallback' },
      ['<C-_>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-Down>'] = { 'scroll_documentation_down', 'fallback' },
      ['<C-Up>'] = { 'scroll_documentation_up', 'fallback' },

      ['<C-y>'] = { 'select_and_accept', 'fallback' },
      ['<C-CR>'] = { 'select_and_accept', 'fallback' },

      ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },

      ['<C-l>'] = { 'snippet_forward', 'fallback' },
      ['<C-h>'] = { 'snippet_backward', 'fallback' },

      ['<C-c>'] = { 'cancel', 'fallback' },
      ['<C-e>'] = { 'hide', 'fallback' },

      ['<Esc>'] = {
        function(cmp)
          cmp.hide()
          return false -- continue
        end,
        'fallback',
      },

      cmdline = {
        ['<C-n>'] = { 'select_next' },
        ['<C-p>'] = { 'select_prev' },
        ['<C-j>'] = { 'select_next' },
        ['<C-k>'] = { 'select_prev' },
        ['<Esc>'] = { -- https://github.com/Saghen/blink.cmp/issues/547#issuecomment-2559100432
          'hide',
          function()
            if vim.fn.getcmdtype() ~= '' then
              vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, true, true), 'n')
            end
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
      documentation = { auto_show = true },
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
        selection = function(ctx)
          return ctx.mode == 'default' and 'preselect' or 'auto_insert'
        end,
      },
    },
    signature = { enabled = true },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
  },
  opts_extend = { 'sources.default' },
}
