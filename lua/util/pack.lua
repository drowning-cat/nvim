local M = {}

setmetatable(M, { __index = vim.pack })

function M.now(callback)
  callback()
end

function M.later(callback)
  vim.schedule(callback)
end

local is_build_event = function(e)
  return e.data.kind == "install" or e.data.kind == "update"
end

local pending_events = {}

local pull_pending = function(src)
  local matches, remaining = {}, {}
  for _, e in ipairs(pending_events) do
    if e.data.spec.src == src and is_build_event(e) then
      table.insert(matches, e)
    else
      table.insert(remaining, e)
    end
  end
  pending_events = remaining
  return matches, remaining
end

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("pack_build", { clear = true }),
  callback = function(e)
    local build = e.data.build
    if e.data.active == false then
      table.insert(pending_events, e)
    elseif build and is_build_event(e) then
      build(e)
    end
  end,
})

-- ```lua
-- pack.add({
--   {
--     src = "https://github.com/nvim-treesitter/nvim-treesitter",
--     data = {
--       build = function()
--         require("nvim-treesitter").update()
--       end,
--     },
--   },
-- })
-- ```
function M.add(specs, opts)
  vim.pack.add(specs, opts)
  for _, spec in ipairs(specs) do
    local build = vim.tbl_get(spec, "data", "build")
    if build then
      local pending = pull_pending(spec.src)
      if not vim.tbl_isempty(pending) then
        build(pending[1], pending)
      end
    end
  end
end

return M
