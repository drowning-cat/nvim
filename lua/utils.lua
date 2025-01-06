local M = {}

--- @generic T
--- @param list1 T[]
--- @param ... T[]: Multiple lists can be provided.
--- @return T[]: A new list containing all elements from the provided lists, combined in order.
--- @description Combines multiple lists into a single list. Useful for working with vim.g, where options are immutable and require reassignment.
function M.list_concat(list1, ...)
  local join_list = {}
  for _, list in ipairs { list1, ... } do
    for _, value in ipairs(list) do
      table.insert(join_list, value)
    end
  end
  return join_list
end

--- @generic T
--- @param list T[]: Target list to *mutate*.
--- @description Removes duplicate elements from the provided list, modifying it in place.
function M.list_remove_dups_mut(list)
  local has_value = {}
  for index, value in ipairs(list) do
    if has_value[value] then
      table.remove(list, index)
    else
      has_value[value] = true
    end
  end
end

--- @class NotifyOpts
--- @field duration? integer: Time in milliseconds to show the notification.
--- @field force? boolean: Whether clear after duration over active notification.

--- @param message string: The notification message to display.
--- @param opts? NotifyOpts: Settings for the notification.
--- @description A wrapper around `vim.notify` that adds support for delayed notifications.
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

--- @description Assigns utility functions to `vim.u`, `vim.util` namespaces
function M.setup()
  vim.u = M
  vim.util = M
end

return M
