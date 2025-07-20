local M = {}

---@param mode string: Mode to check (e.g. 'n', 'v', ...)
---@param lhs string Key sequence to look up
---@param fallback? boolean
function M.keym_fn(mode, lhs, fallback)
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    if lhs == map.lhs then
      if map.callback then
        return map.callback
      end
      if map.rhs then
        return function()
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes(map.rhs, true, false, true), 'n')
        end
      end
    end
  end
  if fallback == nil or fallback == false then
    return nil
  else
    return function()
      vim.fn.feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), 'n')
    end
  end
end

---@param message unknown
function M.notify_send(message)
  vim.fn.system { 'notify-send', tostring(message) }
end

---@param buf? number
function M.find_root(buf)
  return vim.lsp.buf.list_workspace_folders()[1] or vim.fs.root(buf or 0, {
    '.git',
    'Makefile',
    'package.json',
  })
end

---@generic T
---@param from `T`
---@param fun? fun(copy: T): T?
function M.extend(from, fun)
  local copy = vim.deepcopy(from)
  return fun and (fun(copy) or copy) or copy
end

-- NOTE: Win

local W = {}

---@alias Direction 'h'|'j'|'k'|'l'

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
function W.swap_buf(dir, focus)
  focus = focus or true
  swap_win_buf(vim.fn.winnr(), vim.fn.winnr(dir), focus)
end

---@param dir Direction
function W.resize(dir)
  local step = { h = 4, v = 2 }
  -- 1. Horizontal resize
  if dir == 'h' then
    vim.fn.win_move_separator(vim.fn.winnr 'h', -step.h)
  elseif dir == 'l' then
    vim.fn.win_move_separator(vim.fn.winnr 'h', step.h)
  -- 2. Vertical resize
  -- elseif vim.fn.winnr() == vim.fn.winnr 'k' then -- Prevent the statusline from resizing vertically
  --   return
  elseif dir == 'k' then
    vim.fn.win_move_statusline(vim.fn.winnr 'k', -step.v)
  elseif dir == 'j' then
    vim.fn.win_move_statusline(vim.fn.winnr 'k', step.v)
  end
end

---@param win? integer
function W.close(win)
  win = win or 0
  vim.api.nvim_win_call(win, function()
    vim.bo.bufhidden = 'delete'
    vim.cmd.quit()
  end)
end

-- NOTE: Setup

function M.setup()
  vim.u = M
  vim.u.win = W
end

return M
