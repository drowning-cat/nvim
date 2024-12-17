-- Define keymaps for managing Neovim windows similar to
-- those used in tiling window managers

--- @alias Direction 'down'|'left'|'right'|'up'

--- @param dir Direction
--- @param move_cursor? boolean
local swap_buf = function(dir, move_cursor)
  move_cursor = move_cursor or true

  local swap_win_buf = function(win_1_nr, win_2_nr)
    -- Get `win_id`, `buf_id` from the window number
    local win_1, buf_1 = vim.fn.win_getid(win_1_nr), vim.fn.winbufnr(win_1_nr)
    local win_2, buf_2 = vim.fn.win_getid(win_2_nr), vim.fn.winbufnr(win_2_nr)

    -- Store `vim.opt.list`
    local win_1_list = vim.api.nvim_get_option_value('list', { win = win_1 })
    local win_2_list = vim.api.nvim_get_option_value('list', { win = win_2 })

    -- Store views
    vim.fn.win_gotoid(win_1)
    local view_1 = vim.fn.winsaveview()
    vim.fn.win_gotoid(win_2)
    local view_2 = vim.fn.winsaveview()

    -- Swap buffers
    vim.api.nvim_win_set_buf(win_1, buf_2)
    vim.api.nvim_win_set_buf(win_2, buf_1)

    -- Swap `vim.opt.list`
    vim.api.nvim_set_option_value('list', win_1_list, { win = win_2 })
    vim.api.nvim_set_option_value('list', win_2_list, { win = win_1 })

    -- Swap views
    vim.fn.win_gotoid(win_1)
    vim.fn.winrestview(view_2)
    vim.fn.win_gotoid(win_2)
    vim.fn.winrestview(view_1)

    if move_cursor == true then
      vim.fn.win_gotoid(win_2)
    else
      vim.fn.win_gotoid(win_1)
    end
  end

  return function()
    if dir == 'left' then
      swap_win_buf(vim.fn.winnr(), vim.fn.winnr 'h')
    elseif dir == 'right' then
      swap_win_buf(vim.fn.winnr(), vim.fn.winnr 'l')
    elseif dir == 'up' then
      swap_win_buf(vim.fn.winnr(), vim.fn.winnr 'k')
    elseif dir == 'down' then
      swap_win_buf(vim.fn.winnr(), vim.fn.winnr 'j')
    end
  end
end

--- @param dir Direction
local resize = function(dir)
  local step = {
    h = 4,
    v = 2,
  }
  return function()
    -- 1. Horizontal resize
    if dir == 'left' then
      vim.fn.win_move_separator(vim.fn.winnr 'h', -step.h)
    elseif dir == 'right' then
      vim.fn.win_move_separator(vim.fn.winnr 'h', step.h)
    -- 2. Vertical resize
    -- elseif vim.fn.winnr() == vim.fn.winnr 'k' then -- Prevent the statusline from resizing vertically
    --   return
    elseif dir == 'up' then
      vim.fn.win_move_statusline(vim.fn.winnr 'k', -step.v)
    elseif dir == 'down' then
      vim.fn.win_move_statusline(vim.fn.winnr 'k', step.v)
    end
  end
end

return {
  {
    'declancm/maximize.nvim',
    -- stylua: ignore
    keys = {
      { '<C-f>', function() require('maximize').toggle() end, desc = 'Toggle [F]ullscreen' },
    },
  },
  {
    'pogyomo/submode.nvim',
    event = 'VeryLazy',
    config = function()
      -- Close
      vim.keymap.set('n', '<C-q>', '<C-w>q', { desc = 'Close the window' })

      -- Move
      vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move focus left' })
      vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move focus down' })
      vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move focus up' })
      vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move focus right' })
      vim.keymap.set('n', '<C-Left>', '<C-w>h', { desc = 'Move focus left' })
      vim.keymap.set('n', '<C-Down>', '<C-w>j', { desc = 'Move focus down' })
      vim.keymap.set('n', '<C-Up>', '<C-w>k', { desc = 'Move focus up' })
      vim.keymap.set('n', '<C-Right>', '<C-w>l', { desc = 'Move focus right' })

      -- Swap
      vim.keymap.set('n', '<C-S-h>', swap_buf 'left', { desc = 'Swap with buffer left' })
      vim.keymap.set('n', '<C-S-j>', swap_buf 'down', { desc = 'Swap with buffer down' })
      vim.keymap.set('n', '<C-S-k>', swap_buf 'up', { desc = 'Swap with buffer up' })
      vim.keymap.set('n', '<C-S-l>', swap_buf 'right', { desc = 'Swap with buffer right' })
      vim.keymap.set('n', '<C-S-Left>', swap_buf 'left', { desc = 'Swap with buffer left' })
      vim.keymap.set('n', '<C-S-Down>', swap_buf 'down', { desc = 'Swap with buffer down' })
      vim.keymap.set('n', '<C-S-Up>', swap_buf 'up', { desc = 'Swap with buffer up' })
      vim.keymap.set('n', '<C-S-Right>', swap_buf 'right', { desc = 'Swap with buffer right' })

      -- Resize
      local submode = require 'submode'
      submode.create('WinResize', {
        mode = 'n',
        enter = '<C-w>r',
        leave = { '<Esc>', 'q', '<C-c>' },
        hook = {
          on_enter = function()
            vim.notify 'Use { h, j, k, l } or { <Left>, <Down>, <Up>, <Right> } to resize the window'
          end,
          on_leave = function()
            vim.notify ''
          end,
        },
        default = function(register)
          --- @param dir Direction
          --- Patched resize function to redraw vim.notify messages during statusline resizing
          local resize_patched = function(dir)
            local resize_fn = resize(dir)
            return function()
              resize_fn()
              vim.cmd [[ messages ]]
            end
          end
          register('h', resize_patched 'left', { desc = 'Resize left' })
          register('j', resize_patched 'down', { desc = 'Resize down' })
          register('k', resize_patched 'up', { desc = 'Resize up' })
          register('l', resize_patched 'right', { desc = 'Resize right' })
          register('<Left>', resize_patched 'left', { desc = 'Resize left' })
          register('<Down>', resize_patched 'down', { desc = 'Resize down' })
          register('<Up>', resize_patched 'up', { desc = 'Resize up' })
          register('<Right>', resize_patched 'right', { desc = 'Resize right' })
        end,
      })
    end,
  },
}
