local M = {}

function M.sync_colorscheme()
  pcall(vim.cmd.rshada)
end

---@param fallback? string
---@return string|nil
function M.get_colorscheme(fallback)
  if not vim.g.COLORS_NAME then
    M.sync_colorscheme()
  end
  if not vim.g.COLORS_NAME or vim.g.COLORS_NAME == '' then
    return fallback or 'default'
  end
  return vim.g.COLORS_NAME
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
---@field pattern? string

---@alias ColorschemeSpec string|ColorschemePluginSpec

local tbl_wrap = function(v)
  return type(v) == 'table' and v or { v }
end

---@param plugins ColorschemeSpec[]
---@return LazyPluginSpec[]
function M.tune_colorscheme_plugins(plugins)
  plugins = vim.iter(plugins):map(tbl_wrap)

  local get_name = function(plug)
    local get_name = require('lazy.core.plugin').Spec.get_name
    local name = plug.name --\
      or plug[1] and get_name(plug[1])
      or plug.url and get_name(plug.url)
      or plug.dir and get_name(plug.dir)
    return string.gsub(name, '[-.]nvim$', '')
  end

  local match_colorscheme = function(plug, colorscheme)
    local pattern = plug.pattern
    if not pattern then
      local name = get_name(plug)
      if name then
        pattern = string.gsub(name, '-', '%%-') .. '*'
      end
    end
    return vim.iter(tbl_wrap(pattern)):any(function(pat)
      return string.match(colorscheme, pat)
    end)
  end

  local colorscheme = M.get_colorscheme()

  plugins = plugins:map(function(plug)
    if match_colorscheme(plug, colorscheme) then
      return vim.tbl_extend('keep', plug, { lazy = false, priority = 1000 })
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

  vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyDone',
    once = true,
    group = aug,
    callback = function()
      M.load_colorscheme()
    end,
  })
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = aug,
    callback = function()
      M.save_colorscheme()
    end,
  })
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
