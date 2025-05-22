-- snake_case, camelCase, PascalCase, ...
return {
  {
    'chrisgrieser/nvim-spider',
    lazy = true,
    -- stylua: ignore
    keys = {
      { ',e', mode = { 'n', 'o', 'x' }, function() require('spider').motion('e') end },
      { ',w', mode = { 'n', 'o', 'x' }, function() require('spider').motion('w') end },
      { ',b', mode = { 'n', 'o', 'x' }, function() require('spider').motion('b') end },
    },
  },
}
