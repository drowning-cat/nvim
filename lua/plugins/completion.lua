local plugins = {}

---@class KeymapCommandWrapper
---@field [1] blink.cmp.KeymapCommand
---@field [string] unknown
---@field next? boolean

---@alias SuperKeymapCommand KeymapCommandWrapper|blink.cmp.KeymapCommand

---@class SuperKeymapConfig
---@field preset? blink.cmp.KeymapPreset
---@field [string] SuperKeymapCommand[]

---@param key_commands SuperKeymapCommand[]
---@return blink.cmp.KeymapCommand[]
local convert = function(key_commands)
  local key_config = {}
  for i, cmd in ipairs(key_commands) do
    if type(cmd) == 'table' then
      local next = nil
      local cmd_name, args = cmd[1], {}
      for key, val in pairs(cmd) do
        if type(key) == 'number' then
          -- skip
        elseif key == 'next' then
          next = val
        else
          args[key] = val
        end
      end
      key_config[i] = function(cmp)
        local fun, _args = cmp[cmd_name], vim.tbl_isempty(args) and args or nil
        local ret = fun(_args)
        -- stylua: ignore
        if next == nil then return ret end
        return not next
      end
    else
      key_config[i] = cmd
    end
  end
  return key_config
end

---@param super_keymap_config SuperKeymapConfig
---@return blink.cmp.KeymapConfig
local keymap_config = function(super_keymap_config)
  local keymap_config = {}
  for key, val in pairs(super_keymap_config) do
    if key == 'preset' then
      keymap_config[key] = val
    else
      keymap_config[key] = convert(val)
    end
  end
  return keymap_config
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
    keymap = keymap_config {
      preset = 'none',
      -- Move
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<C-j>'] = { 'select_next', 'fallback' },
      ['<C-k>'] = { 'select_prev', 'fallback' },
      ['<C-n>'] = { { 'select_next', auto_insert = true } }, -- no fallback
      ['<C-p>'] = { { 'select_prev', auto_insert = true } }, -- no fallback
      -- Accept
      ['<C-y>'] = { 'select_and_accept' },
      ['<C-CR>'] = { 'select_and_accept' }, -- no fallback
      -- Show
      ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' }, -- no fallback
      -- Cancel
      ['<C-c>'] = { 'cancel', 'fallback' },
      -- Hide
      ['<C-e>'] = { 'hide' }, -- no fallback
      ['<Esc>'] = { { 'hide', next = true }, 'fallback' },
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
      keymap = keymap_config {
        preset = 'none',
        -- Move
        ['<Down>'] = { { 'hide', next = true }, 'fallback' },
        ['<Up>'] = { { 'hide', next = true }, 'fallback' },
        ['<C-Down>'] = { 'select_next' },
        ['<C-Up>'] = { 'select_prev' },
        ['<Tab>'] = { 'select_next' },
        ['<S-Tab>'] = { 'select_prev' },
        ['<C-j>'] = { 'select_next' },
        ['<C-k>'] = { 'select_prev' },
        ['<C-n>'] = { { 'select_next', auto_insert = true } },
        ['<C-p>'] = { { 'select_prev', auto_insert = true } },
        -- Accept
        ['<C-y>'] = { 'select_and_accept' },
        -- Show
        ['<C-Space>'] = { 'show' },
        -- Hide
        ['<C-c>'] = { nil }, -- No need to bind
        ['<C-e>'] = { 'hide' },
        -- stylua: ignore
        ['<Esc>'] = { function() vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, false, true), 'n') end,
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
