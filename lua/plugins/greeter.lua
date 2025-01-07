local configuration = function()
  local theta = require 'alpha.themes.theta'
  local theme = theta.config

  local button_text = function(icon, text)
    if vim.g.have_nerd_font then
      return icon .. ' ' .. text
    else
      return text
    end
  end

  local dashboard = require 'alpha.themes.dashboard'
  local buttons = {
    type = 'group',
    val = {
      { type = 'text', val = 'Quick links', opts = { hl = 'SpecialComment', position = 'center' } },
      { type = 'padding', val = 1 },
      dashboard.button('e', button_text('', 'Edit'), '<cmd>ene<CR>'),
      dashboard.button('i', button_text('', 'Insert'), '<cmd>ene | startinsert<CR>'),
      dashboard.button('f', button_text('', 'Find'), '<cmd>Telescope find_files<CR>'),
      dashboard.button('g', button_text('', 'Grep'), '<cmd>Telescope live_grep<CR>'),
      dashboard.button('l', button_text('󱐥', 'Lazy'), '<cmd>Lazy<CR>'),
      dashboard.button('m', button_text('', 'Mason'), '<cmd>Mason<CR>'),
      dashboard.button('q', button_text('󰩈', 'Quit'), '<cmd>qa<CR>'),
    },
    position = 'center',
  }

  theme.layout[2].val = { '', '', '', '', '', '', '', '', '' } -- padding
  theme.layout[6] = buttons

  return theme
end

return {
  'goolord/alpha-nvim',
  cond = #vim.fn.argv() == 0,
  dependencies = {
    'echasnovski/mini.icons',
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('alpha').setup(configuration())
  end,
}
