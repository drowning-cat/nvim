---@module 'quicker'

---@type table<integer, { height: number, view: quicker.WinViewDict }>
local win_config = {}

---@param loclist? boolean
---@return integer
local next_qfid = function(loclist)
  if loclist then
    return vim.fn.getloclist(0, { id = 0 }).id
  else
    return vim.fn.getqflist({ id = 0 }).id
  end
end

---@param win integer quickfix win id
---@return nil|integer
local qfid = function(win)
  local wininfo = vim.fn.getwininfo(win)[1] or {}
  if wininfo.loclist == 1 then
    return vim.fn.getloclist(win, { id = 0 }).id
  end
  if wininfo.quickfix == 1 then
    return vim.fn.getqflist({ id = 0 }).id
  end
  return nil
end

local aug = vim.api.nvim_create_augroup('qf_restore', { clear = true })

vim.api.nvim_create_autocmd('WinResized', {
  group = aug,
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local wininfo = vim.fn.getwininfo(win)[1]
      if wininfo.quickfix == 1 then
        local id = qfid(win)
        if id then
          win_config[id] = {
            height = vim.api.nvim_win_get_height(win),
            view = vim.api.nvim_win_call(win, vim.fn.winsaveview),
          }
        end
      end
    end
  end,
})

-- :grep, :copen; :cnewer, ...
vim.api.nvim_create_autocmd('BufRead', {
  group = aug,
  pattern = 'quickfix',
  callback = function()
    local win = vim.api.nvim_get_current_win()
    local id = qfid(win)
    if not id then
      return
    end
    local wconf = win_config[id]
    if not wconf then
      return
    end
    -- NOTE: Restore `view`
    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview(wconf.view)
      end)
    end)
    -- NOTE: Restore `height`
    -- Skip if `:copen <count>`
    if not vim.fn.histget('cmd', -1):find 'copen? ?%d+' then
      vim.api.nvim_win_set_height(win, wconf.height)
    end
  end,
})

---@param opts quicker.OpenOpts
local quicker_toggle = function(opts)
  local id = next_qfid(opts.loclist)
  local wconf = win_config[id] or {}
  require('quicker').toggle(vim.tbl_extend('keep', opts, {
    height = wconf.height,
    min_height = 10,
    view = wconf.view,
    focus = true,
    open_cmd_mods = { ---@diagnostic disable-line: missing-fields
      split = 'botright',
    },
  } --[[@as quicker.OpenOpts]]))
end

return {
  {
    'kevinhwang91/nvim-bqf',
    ft = 'qf',
    opts = {
      preview = {
        auto_preview = false,
      },
    },
  },
  {
    'stevearc/quicker.nvim',
    ft = 'qf',
    version = false,
    ---@type quicker.SetupOptions
    opts = {
      max_filename_width = function()
        return 20
      end,
      on_qf = function()
        vim.wo.signcolumn = 'yes:1'
      end,
    },
    -- stylua: ignore
    keys = {
      { '<leader>l', function() quicker_toggle {} end, desc = 'Toggle quickfix [l]ist' },
      { '<leader>L', function() quicker_toggle { loclist = true } end, desc = 'Toggle [L]oclist list' },
    },
  },
}
