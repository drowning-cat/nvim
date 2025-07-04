local M = {}

M.registery = {}

function M.sync_colorscheme()
  pcall(vim.cmd.rshada)
end

---@param fallback? string
---@return string|nil
function M.get_colorscheme(fallback)
  if not vim.g.COLORS_NAME then
    M.sync_colorscheme()
  end
  if vim.g.COLORS_NAME and vim.g.COLORS_NAME ~= '' then
    return vim.g.COLORS_NAME
  else
    return fallback
  end
end

---@param colorscheme? string
function M.save_colorscheme(colorscheme)
  colorscheme = colorscheme or vim.g.colors_name
  if M.get_colorscheme() == colorscheme then
    return
  end
  vim.g.COLORS_NAME = colorscheme
  vim.cmd.wshada()
end

function M.load_colorscheme()
  return pcall(vim.cmd.colorscheme, M.get_colorscheme())
end

---@module 'lazy.types'

---@class ColorschemePluginSpec : LazyPluginSpec
---@field pattern? string|string[]

---@alias ColorschemeSpec string|ColorschemePluginSpec

local tbl_wrap = function(v)
  return type(v) == 'table' and v or { v }
end

---@param plugins ColorschemeSpec[]
---@return LazyPluginSpec[]
function M.tune_colorscheme_plugins(plugins)
  plugins = vim.iter(plugins):map(tbl_wrap)

  ---@param plug LazyPluginSpec
  local get_name = function(plug)
    local get_name = require('lazy.core.plugin').Spec.get_name
    local name = plug.name --[[@as string]]
      or plug[1] and get_name(plug[1])
      or plug.url and get_name(plug.url)
      or plug.dir and get_name(plug.dir)
    return string.gsub(name, '[-.]nvim$', '')
  end

  local in_registery = function(plug, colorscheme)
    local name = plug[1] or plug.url or plug.dir
    local reg = M.registery[colorscheme]
    if colorscheme:match 'base16%-' and name == 'RRethy/base16-nvim' then
      return true
    end
    if reg == name then
      return true
    end
  end

  local match_colorscheme = function(plug, colorscheme)
    if in_registery(plug, colorscheme) then
      return true
    end
    local pattern = plug.pattern
    if not pattern then
      local name = get_name(plug)
      if name then
        pattern = string.gsub(name, '-', '%%-')
      end
    end
    return vim.iter(tbl_wrap(pattern)):any(function(pat)
      return string.match(colorscheme, pat)
    end)
  end

  local colorscheme = M.get_colorscheme()

  -- local make_config = function(plug)
  --   local config = plug.config
  --   return function(lazy_plug, opts)
  --     if type(config) == 'function' then
  --       config(lazy_plug, opts)
  --     end
  --     if config == true then
  --       require(get_name(plug)).setup(lazy_plug, opts)
  --     end
  --     M.load_colorscheme()
  --   end
  -- end

  plugins = plugins:map(function(plug)
    if match_colorscheme(plug, colorscheme) then
      return vim.tbl_extend('force', plug, {
        lazy = false,
        priority = 1000,
        -- config = make_config(plug),
      })
    else
      return vim.tbl_extend('keep', plug, { lazy = true })
    end
  end)

  return plugins:totable()
end

---@param plugins ColorschemeSpec[]
---@return LazyPluginSpec[]
function M.lazy_setup(plugins)
  local aug = vim.api.nvim_create_augroup('save_colors', { clear = true })
  local on_enter = function()
    if vim.g.colors_name == M.get_colorscheme() then
      return true
    else
      M.load_colorscheme()
    end
  end
  vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyDone',
    once = true,
    group = aug,
    callback = on_enter,
  })
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    group = aug,
    callback = on_enter,
  })
  -- vim.api.nvim_create_autocmd('ColorScheme', {
  --   group = aug,
  --   callback = function(event)
  --     M.save_colorscheme(event.match)
  --   end,
  -- })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = aug,
    callback = function()
      M.sync_colorscheme()
      M.save_colorscheme(M.get_colorscheme())
    end,
  })
  return M.tune_colorscheme_plugins(plugins)
end

return M
