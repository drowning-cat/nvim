---@module 'snacks'

vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

local is_netrw = vim.iter(vim.fn.argv()):any(function(file)
  return vim.fn.isdirectory(file) == 1
end)

if is_netrw then
  vim.api.nvim_buf_set_name(1, '')
end

local init_win = vim.api.nvim_get_current_win()
local arg1 = vim.fn.argv(0) --[[@as string]]

vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = function()
    if #vim.fn.argv() == 0 then
      require('snacks.dashboard').setup()
    elseif is_netrw then
      Snacks.picker.explorer { cwd = arg1 }
      local keys = nil
      pcall(function()
        keys = vim.deepcopy(Snacks.config.dashboard.preset.keys)
        keys[#keys].action = ':qa'
      end)
      local win = Snacks.dashboard.open { ---@diagnostic disable-line: missing-fields
        win = init_win,
        preset = { keys = keys },
      }
      vim.b[win.buf].ministatusline_disable = true
      vim.bo[1].bufhidden = 'wipe'
      vim.bo[1].buftype = 'nofile'
      vim.bo[1].buflisted = false
    end
  end,
})

return {
  'folke/snacks.nvim',
  ---@type snacks.Config
  opts = {
    dashboard = {
      enabled = false,
      preset = {
        keys = {
          { icon = ' ', key = 'n', desc = 'New', action = ':ene' },
          { icon = ' ', key = 'i', desc = 'Insert', action = ':ene | startinsert' },
          { icon = ' ', key = 'f', desc = 'Find', action = ":lua Snacks.dashboard.pick('files')" },
          { icon = ' ', key = 'g', desc = 'Grep', action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = ' ', key = 'r', desc = 'Recent', action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
          { icon = '󰦛 ', key = 's', desc = 'Session', section = 'session' },
          { icon = ' ', key = 'q', desc = 'Quit', action = ':q' },
        },
      },
      sections = {
        { title = { 'Recent Files', hl = 'Special' }, align = 'center', padding = 1 },
        { section = 'recent_files', limit = 10, padding = 2 },
        { title = { 'Quick Links', hl = 'Special' }, align = 'center', padding = 1 },
        { section = 'keys', padding = 2 },
      },
    },
  },
}
