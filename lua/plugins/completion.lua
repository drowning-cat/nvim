local extra = {}

-- stylua: ignore start
extra.select_next__auto_insert = function(cmp) cmp.select_next { auto_insert = true } end
extra.select_prev__auto_insert = function(cmp) cmp.select_prev { auto_insert = true } end
extra.select_and_accept__no_expand = function(cmp) cmp.select_and_accept() end
extra.hide_and_next = function(cmp) cmp.hide(); return false end
-- stylua: ignore end
extra.cmd_accept = function(cmp)
  cmp.select_and_accept {
    callback = function()
      vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n')
    end,
  }
end
extra.cmdline_cancel = function()
  vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, false, true), 'n')
end
extra.hide__no_stop = function(cmp)
  cmp.hide()
  return false
end

return {
  'saghen/blink.cmp',
  version = false,
  build = 'cargo build --release',
  event = { 'InsertEnter', 'CmdlineEnter' },
  dependencies = {
    { 'rafamadriz/friendly-snippets' },
    { 'echasnovski/mini.icons' },
    -- Compatibility layer for `nvim-cmp` completion sources
    -- { 'saghen/blink.compat', version = '*', opts = {} },
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = 'none',
      -- Move
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<C-j>'] = { 'select_next', 'fallback' },
      ['<C-k>'] = { 'select_prev', 'fallback' },
      ['<C-n>'] = { extra.select_next__auto_insert }, -- no fallback
      ['<C-p>'] = { extra.select_prev__auto_insert }, -- no fallback
      -- Accept
      ['<C-y>'] = { 'select_and_accept' },
      ['<C-CR>'] = { extra.select_and_accept__no_expand }, -- no fallback
      -- Show
      ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' }, -- no fallback
      -- Cancel
      ['<C-c>'] = { 'cancel', 'fallback' },
      -- Hide
      ['<C-e>'] = { 'hide' }, -- no fallback
      -- stylua: ignore
      ['<Esc>'] = { extra.hide_and_next, 'fallback' }, -- and fallback
      -- Scroll
      ['<C-d>'] = { 'scroll_documentation_down' },
      ['<C-u>'] = { 'scroll_documentation_up' },
      -- Snippet
      ['<C-l>'] = { 'snippet_forward', 'fallback' },
      ['<C-h>'] = { 'snippet_backward', 'fallback' },
    },
    cmdline = {
      keymap = {
        ['<Down>'] = { extra.hide__no_stop, 'fallback' },
        ['<Up>'] = { extra.hide__no_stop, 'fallback' },
        ['<C-Down>'] = { 'select_next', 'fallback' },
        ['<C-Up>'] = { 'select_prev', 'fallback' },
        ['<C-j>'] = { 'select_next' },
        ['<C-k>'] = { 'select_prev' },
        ['<C-n>'] = { extra.select_next__auto_insert },
        ['<C-p>'] = { extra.select_prev__auto_insert },
        ['<C-y>'] = { 'select_and_accept' },
        ['<C-Space>'] = { 'show' },
        ['<C-c>'] = { nil }, -- No need to bind
        ['<C-e>'] = { 'hide' },
        ['<Esc>'] = { extra.cmdline_cancel },
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
      default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
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
