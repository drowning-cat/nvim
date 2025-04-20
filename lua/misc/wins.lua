local M = {}

---@alias Direction 'down'|'left'|'right'|'up'

---@param win_1_nr integer
---@param win_2_nr integer
---@param focus? boolean
local swap_win_buf = function(win_1_nr, win_2_nr, focus)
  -- Get `win_id`, `buf_id` from the window number
  local win_1, buf_1 = vim.fn.win_getid(win_1_nr), vim.fn.winbufnr(win_1_nr)
  local win_2, buf_2 = vim.fn.win_getid(win_2_nr), vim.fn.winbufnr(win_2_nr)

  -- Store `vim.o.list`
  local win_1_list = vim.wo[win_1].list
  local win_2_list = vim.wo[win_2].list

  if vim.wo[win_1].winfixbuf or vim.wo[win_2].winfixbuf then
    return
  end

  -- Store `vim.o.foldenable`
  local win_1_folds_enabled = vim.wo[win_1].foldenable
  local win_2_folds_enabled = vim.wo[win_2].foldenable
  -- Disable `vim.o.foldenable`
  vim.wo[win_1].foldenable = false
  vim.wo[win_2].foldenable = false

  -- Store views
  local view_1 = vim.api.nvim_win_call(win_1, vim.fn.winsaveview)
  local view_2 = vim.api.nvim_win_call(win_2, vim.fn.winsaveview)

  -- Swap buffers
  vim.api.nvim_win_set_buf(win_1, buf_2)
  vim.api.nvim_win_set_buf(win_2, buf_1)

  -- Swap `vim.o.list`
  vim.wo[win_2].list = win_1_list
  vim.wo[win_1].list = win_2_list

  -- Swap views
  vim.api.nvim_win_call(win_1, function()
    vim.fn.winrestview(view_2)
  end)
  vim.api.nvim_win_call(win_2, function()
    vim.fn.winrestview(view_1)
  end)

  -- Restore `vim.o.foldenable`
  vim.wo[win_2].foldenable = win_1_folds_enabled
  vim.wo[win_1].foldenable = win_2_folds_enabled

  if focus == true then
    vim.fn.win_gotoid(win_2)
  end
end

---@param dir Direction
---@param focus? boolean
function M.swap_buf(dir, focus)
  focus = focus or true

  if dir == 'left' then
    swap_win_buf(vim.fn.winnr(), vim.fn.winnr 'h', focus)
  elseif dir == 'right' then
    swap_win_buf(vim.fn.winnr(), vim.fn.winnr 'l', focus)
  elseif dir == 'up' then
    swap_win_buf(vim.fn.winnr(), vim.fn.winnr 'k', focus)
  elseif dir == 'down' then
    swap_win_buf(vim.fn.winnr(), vim.fn.winnr 'j', focus)
  end
end

---@param dir Direction
function M.resize(dir)
  local step = {
    h = 4,
    v = 2,
  }
  -- 1. Horizontal resize
  if dir == 'left' then
    vim.fn.win_move_separator(vim.fn.winnr 'h', -step.h)
  elseif dir == 'right' then
    vim.fn.win_move_separator(vim.fn.winnr 'h', step.h)
    -- 2. Vertical resize
    -- elseif vim.fn.winnr() == vim.fn.winnr 'k' then -- Prevent the statusline from resizing vertically
    --   return
  elseif dir == 'up' then
    vim.fn.win_move_statusline(vim.fn.winnr 'k', -step.v)
  elseif dir == 'down' then
    vim.fn.win_move_statusline(vim.fn.winnr 'k', step.v)
  end
end

---@param win? integer
function M.close(win)
  win = win or 0
  vim.api.nvim_win_call(win, function()
    vim.bo.bufhidden = 'delete'
    vim.cmd 'q'
  end)
end

return M
