local M = {}

---@class NotifyOpts
---@field duration? integer: Time in milliseconds to show the notification.
---@field force? boolean: Whether clear after duration over active notification.

-- A wrapper around `vim.notify` that adds support for delayed notifications.
---@param message string: The notification message to display.
---@param opts? NotifyOpts: Settings for the notification.
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
function M.keymap_get(mode, lhs)
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
  return function()
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), 'n')
  end
end

-- Calls `vim.fn.system { 'notify-send', message }`
---@param message unknown
function M.notify_send(message)
  vim.fn.system { 'notify-send', tostring(message) }
end

local root_names = { '.git', 'Makefile', 'package.json' }
local root_cache = {}
-- Change directory to the root folder
function M.cdroot()
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then
    return
  end
  path = vim.fs.dirname(path)
  local root = root_cache[path]
  if root == nil then
    local root_file = vim.fs.find(root_names, { path = path, upward = true })[1]
    if root_file == nil then
      return
    end
    root = vim.fs.dirname(root_file)
    root_cache[path] = root
  end
  vim.fn.chdir(root)
end

-- Assigns utility functions to `vim.u`, `vim.util` namespaces
function M.setup()
  vim.u = M
  vim.util = M
end

return M
