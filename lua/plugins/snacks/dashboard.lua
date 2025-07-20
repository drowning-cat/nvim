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
      Snacks.util.set_hl({
        Desc = 'Normal',
        Icon = 'Normal',
        Key = 'Normal',
        Dir = 'Normal',
      }, { prefix = 'SnacksDashboard' })
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
      width = 50,
      preset = {
        keys = {
          { icon = ' ', key = 'i', desc = 'Insert', action = ':ene | startinsert' },
          { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
          { icon = '󰦛 ', key = 's', desc = 'Session', section = 'session' },
          { icon = ' ', key = 'q', desc = 'Quit', action = ':q' },
        },
      },
      sections = {
        { text = string.format('NVIM %s', vim.version()), align = 'center', padding = 2 },
        { section = 'recent_files', limit = 7, padding = 1 },
        { section = 'keys' },
      },
    },
  },
}
