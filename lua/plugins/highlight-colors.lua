return {
  'brenoprata10/nvim-highlight-colors',
  event = 'VeryLazy',
  opts = {
    ---@usage 'background'|'foreground'|'virtual'
    render = 'virtual',
    ---@usage 'inline'|'eol'|'eow'
    virtual_symbol_position = 'eow',
    virtual_symbol = '⚈',
    virtual_symbol_prefix = ' ',
    virtual_symbol_suffix = '',
  },
  -- stylua: ignore
  keys = {
    { '<leader>tc', function() require('nvim-highlight-colors').toggle() end, desc = '[T]oggle [C]colors' },
  },
}
