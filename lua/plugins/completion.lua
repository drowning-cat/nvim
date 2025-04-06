local plugins = {}

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
extra.smart_tab = function(cmp)
  if cmp.snippet_active() then
    return cmp.accept()
  else
    return cmp.select_and_accept()
  end
end

---@module 'luasnip'
table.insert(plugins, {
  'L3MON4D3/LuaSnip',
  build = 'make install_jsregexp',
  lazy = true,
  dependencies = { 'rafamadriz/friendly-snippets' },
  config = function(_, opts)
    require('luasnip.config').setup(opts)
    local snippets_folder = vim.fn.stdpath 'config' .. '/snippets'
    require('luasnip.loaders.from_lua').lazy_load { paths = { snippets_folder } }
    require('luasnip.loaders.from_vscode').lazy_load()
    require('luasnip.loaders.from_vscode').lazy_load { paths = { snippets_folder } }
  end,
})

---@module 'blink.cmp'
table.insert(plugins, {
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
      ['<Tab>'] = { extra.smart_tab, 'snippet_forward', 'fallback' },
      ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
      ['<C-y>'] = { 'select_and_accept' },
      ['<C-CR>'] = { extra.select_and_accept__no_expand }, -- no fallback
      -- Show
      ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' }, -- no fallback
      -- Cancel
      ['<C-c>'] = { 'cancel', 'fallback' },
      -- Hide
      ['<C-e>'] = { 'hide' }, -- no fallback
      ['<Esc>'] = { extra.hide_and_next, 'fallback' }, -- and fallback
      -- Scroll
      ['<C-d>'] = { 'scroll_documentation_down' },
      ['<C-u>'] = { 'scroll_documentation_up' },
      ['<C-]>'] = { 'scroll_documentation_down' },
      ['<C-_>'] = { 'scroll_documentation_up' },
      -- Snippet
      ['<C-l>'] = { 'snippet_forward', 'fallback' },
      ['<C-h>'] = { 'snippet_backward', 'fallback' },
    },
    cmdline = {
      completion = {
        menu = {
          auto_show = true,
        },
      },
      keymap = {
        preset = 'none',
        -- Move
        ['<Down>'] = { extra.hide__no_stop, 'fallback' },
        ['<Up>'] = { extra.hide__no_stop, 'fallback' },
        ['<C-Down>'] = { 'select_next' },
        ['<C-Up>'] = { 'select_prev' },
        ['<Tab>'] = { 'select_next' },
        ['<S-Tab>'] = { 'select_prev' },
        ['<C-j>'] = { 'select_next' },
        ['<C-k>'] = { 'select_prev' },
        ['<C-n>'] = { extra.select_next__auto_insert },
        ['<C-p>'] = { extra.select_prev__auto_insert },
        -- Accept
        ['<C-y>'] = { 'select_and_accept' },
        -- Show
        ['<C-Space>'] = { 'show' },
        -- Hide
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
              highlight = '',
              text = function(ctx)
                if vim.fn.getcmdtype() == ':' then
                else
                  return '[' .. ctx.source_name .. ']'
                end
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
    snippets = {
      preset = 'luasnip',
    },
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
})

return plugins
