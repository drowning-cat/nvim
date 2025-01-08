return {
  'toppair/peek.nvim',
  cmd = { 'MPreviewOpen', 'MPreviewClose' },
  build = 'deno task --quiet build:fast',
  config = function()
    local peek = require 'peek'
    peek.setup()
    vim.api.nvim_create_user_command('MPreviewOpen', peek.open, {})
    vim.api.nvim_create_user_command('MPreviewClose', peek.close, {})
  end,
}
