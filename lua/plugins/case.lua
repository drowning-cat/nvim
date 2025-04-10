-- https://github.com/chrisgrieser/nvim-spider/blob/main/lua/spider/init.lua
local function getline(lnum)
  local lineContent = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)
  return lineContent[1]
end
local function normal(keys)
  vim.cmd.normal { keys, bang = true }
end
local function motion(key, motionOpts)
  local strFuncs = require('spider.utf8-support').stringFuncs
  local globalOpts = require('spider.config').globalOpts
  local opts = motionOpts and vim.tbl_deep_extend('force', globalOpts, motionOpts) or globalOpts
  if not (key == 'w' or key == 'e' or key == 'b' or key == 'ge') then
    local msg = 'Invalid key: ' .. key .. '\nOnly `w`, `e`, `b`, and `ge` are supported.'
    vim.notify(msg, vim.log.levels.ERROR, { title = 'nvim-spider' })
    return
  end
  local startPos = vim.api.nvim_win_get_cursor(0)
  local row, col = unpack(startPos)
  local lastRow = vim.api.nvim_buf_line_count(0)
  local forwards = key == 'w' or key == 'e'
  local line = getline(row)
  local offset, _ = strFuncs.initPos(line, col)
  for _ = 1, opts.count or vim.v.count1, 1 do ---@diagnostic disable-line: undefined-field
    while true do
      local result = require('spider.motion-logic').getNextPosition(line, offset, key, opts)
      if result then
        offset = result
        break
      end
      offset = 0
      row = forwards and row + 1 or row - 1
      if row > lastRow or row < 1 then
        return
      end
      line = getline(row)
    end
  end
  col = strFuncs.offset(line, offset) - 1
  local mode = vim.api.nvim_get_mode().mode
  local isOpPendingMode = mode:sub(1, 2) == 'no'
  if isOpPendingMode then
    if opts.consistentOperatorPending then
      local opPending = require 'spider.operator-pending'
      opPending.setEndpoints(startPos, { row, col }, { inclusive = key == 'e' })
      return
    end
    if key == 'e' then
      offset = offset + 1
      col = strFuncs.offset(line, offset) - 1
    end
    if col == #line then
      normal 'v'
      offset = offset - 1
      col = strFuncs.offset(line, offset) - 1
    end
  end
  local shouldOpenFold = vim.tbl_contains(vim.opt_local.foldopen:get(), 'hor')
  if mode == 'n' and shouldOpenFold then
    normal 'zv'
  end
  vim.api.nvim_win_set_cursor(0, { row, col })
end

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
  {
    'chrisgrieser/nvim-various-textobjs',
    event = 'VeryLazy',
    keys = {
      {
        'ie',
        mode = { 'o', 'x' },
        function()
          motion('w', { count = vim.v.count1 - 1 })
          require('various-textobjs').subword 'inner'
        end,
      },
      {
        'ae',
        mode = { 'o', 'x' },
        function()
          motion('w', { count = vim.v.count1 - 1 })
          require('various-textobjs').subword 'outer'
        end,
      },
    },
  },
}
