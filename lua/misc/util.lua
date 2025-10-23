local M = {}

---@class NotifyOpts
---@field duration? integer: Time in milliseconds to show the notification
---@field force? boolean: Whether clear after duration over active notification

-- A wrapper around `vim.notify` that adds support for delayed notifications
---@param message string: The notification message to display
---@param opts? NotifyOpts: Settings for the notification
function M.notify(message, opts)
  opts = vim.tbl_extend('keep', opts or {}, {
    duration = nil,
    force = true,
  })

  local get_last_message = function()
    return vim.fn.execute '1messages'
  end

  vim.notify(message)

  if opts.duration then
    vim.defer_fn(function()
      if opts.force or get_last_message() == message then
        vim.notify ''
      end
    end, opts.duration)
  end
end

-- Returns the function defined via vim.keymap.set
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

-- Calls `vim.fn.system { 'notify-send', message }`
---@param message unknown
function M.notify_send(message)
  vim.fn.system { 'notify-send', tostring(message) }
end

-- Find projects root directory for the current buffer
---@param buf? number
function M.find_root(buf)
  return vim.lsp.buf.list_workspace_folders()[1] or vim.fs.root(buf or 0, {
    '.git',
    'Makefile',
    'package.json',
  })
end

-- Utility for extending tables
---@generic T
---@param from `T`
---@param fun? fun(copy: T): T?
function M.extend(from, fun)
  local copy = vim.deepcopy(from)
  return fun and (fun(copy) or copy) or copy
end

-- Assigns utility functions to `vim.u`, `vim.util` namespaces
function M.setup()
  vim.u = M
  vim.util = M
end

return M
