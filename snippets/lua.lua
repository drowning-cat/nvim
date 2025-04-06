local ls = require 'luasnip'

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s('vp', { t 'vim.print(', i(1), t ')' }),
  s('vpq', { t "vim.print('", i(1), t "')" }),
}
