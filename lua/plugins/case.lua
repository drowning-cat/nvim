return {
  {
    'chrisgrieser/nvim-spider',
    lazy = true,
    keys = {
      -- { 'e', 'e', mode = { 'n', 'o', 'x' }, noremap = true },
      -- { 'w', 'w', mode = { 'n', 'o', 'x' }, noremap = true },
      -- { 'b', 'w', mode = { 'n', 'o', 'x' }, noremap = true },
      { ',e', mode = { 'n', 'o', 'x' }, "<cmd>lua require('spider').motion('e')<CR>" },
      { ',w', mode = { 'n', 'o', 'x' }, "<cmd>lua require('spider').motion('w')<CR>" },
      { ',b', mode = { 'n', 'o', 'x' }, "<cmd>lua require('spider').motion('b')<CR>" },
    },
  },
  -- {
  --   'chrisgrieser/nvim-various-textobjs',
  --   event = 'VeryLazy',
  --   keys = {
  --     { 'ae', mode = { 'o', 'x' }, '<cmd>lua require("various-textobjs").subword("outer")<CR>' },
  --     { 'ie', mode = { 'o', 'x' }, '<cmd>lua require("various-textobjs").subword("inner")<CR>' },
  --   },
  -- },
}
