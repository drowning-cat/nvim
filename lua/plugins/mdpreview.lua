return {
  'toppair/peek.nvim',
  cmd = { 'Mdopen', 'Mdclose' },
  build = 'deno task --quiet build:fast',
  config = function()
    local peek = require 'peek'
    peek.setup()
    vim.api.nvim_create_user_command('Mdopen', peek.open, {})
    vim.api.nvim_create_user_command('Mdclose', peek.close, {})
  end,
}
