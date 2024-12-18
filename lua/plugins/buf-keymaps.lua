-- Tile-like keymaps for managing windows
--
return {
  {
    'mrjones2014/smart-splits.nvim',
    init = function()
      vim.keymap.set('n', '<C-q>', '<C-w>q', { desc = 'Close the window' })
    end,
    -- stylua: ignore
    keys = {
      -- Resize
      -- { '<C-w>r', function() require('smart-splits').start_resize_mode() end, desc = 'Start [R]esize mode' },
      { '<C-Left>', function() require('smart-splits').resize_left() end, desc = 'Resize left' },
      { '<C-Down>', function() require('smart-splits').resize_down() end, desc = 'Resize down' },
      { '<C-Up>', function() require('smart-splits').resize_up() end, desc = 'Resize up' },
      { '<C-Right>', function() require('smart-splits').resize_right() end, desc = 'Resize right' },
      -- Move focus
      { '<C-h>', function() require('smart-splits').move_cursor_left() end, desc = 'Move focus left' },
      { '<C-j>', function() require('smart-splits').move_cursor_down() end, desc = 'Move focus down' },
      { '<C-k>', function() require('smart-splits').move_cursor_up() end, desc = 'Move focus up' },
      { '<C-l>', function() require('smart-splits').move_cursor_right() end, desc = 'Move focus right' },
      -- { '<C-Left>', function() require('smart-splits').move_cursor_left() end, desc = 'Move focus left' },
      -- { '<C-Down>', function() require('smart-splits').move_cursor_down() end, desc = 'Move focus down' },
      -- { '<C-Up>', function() require('smart-splits').move_cursor_up() end, desc = 'Move focus up' },
      -- { '<C-Right>', function() require('smart-splits').move_cursor_right() end, desc = 'Move focus right' },
      -- Swap buffers
      { '<C-S-h>', function() require('smart-splits').swap_buf_left() end, desc = 'Swap with buffer left' },
      { '<C-S-j>', function() require('smart-splits').swap_buf_down() end, desc = 'Swap with buffer down' },
      { '<C-S-k>', function() require('smart-splits').swap_buf_up() end, desc = 'Swap with buffer up' },
      { '<C-S-l>', function() require('smart-splits').swap_buf_right() end, desc = 'Swap with buffer right' },
      { '<C-S-Left>', function() require('smart-splits').swap_buf_left() end, desc = 'Swap with buffer left' },
      { '<C-S-Down>', function() require('smart-splits').swap_buf_down() end, desc = 'Swap with buffer down' },
      { '<C-S-Up>', function() require('smart-splits').swap_buf_up() end, desc = 'Swap with buffer up' },
      { '<C-S-Right>', function() require('smart-splits').swap_buf_right() end, desc = 'Swap with buffer right' },
    },
  },
  {
    'declancm/maximize.nvim',
    -- stylua: ignore
    keys = {
      { '<C-f>', function() require('maximize').toggle() end, desc = 'Toggle [F]ullscreen' },
    },
  },
}
