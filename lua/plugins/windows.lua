return {
  {
    'declancm/maximize.nvim',
    -- stylua: ignore
    keys = {
      { '<C-f>', function() require('maximize').toggle() end, desc = 'Toggle [F]ullscreen' },
    },
  },
  {
    'mrjones2014/smart-splits.nvim',
    event = 'VeryLazy',
    dependencies = {
      'pogyomo/submode.nvim',
    },
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
      vim.keymap.set('n', '<C-S-h>', require('smart-splits').swap_buf_left, { desc = 'Swap with buffer left' })
      vim.keymap.set('n', '<C-S-j>', require('smart-splits').swap_buf_down, { desc = 'Swap with buffer down' })
      vim.keymap.set('n', '<C-S-k>', require('smart-splits').swap_buf_up, { desc = 'Swap with buffer up' })
      vim.keymap.set('n', '<C-S-l>', require('smart-splits').swap_buf_right, { desc = 'Swap with buffer right' })
      vim.keymap.set('n', '<C-S-Left>', require('smart-splits').swap_buf_left, { desc = 'Swap with buffer left' })
      vim.keymap.set('n', '<C-S-Down>', require('smart-splits').swap_buf_down, { desc = 'Swap with buffer down' })
      vim.keymap.set('n', '<C-S-Up>', require('smart-splits').swap_buf_up, { desc = 'Swap with buffer up' })
      vim.keymap.set('n', '<C-S-Right>', require('smart-splits').swap_buf_right, { desc = 'Swap with buffer right' })

      -- Resize
      local submode = require 'submode'
      submode.create('WinResize', {
        mode = 'n',
        enter = '<C-w>r',
        leave = { '<Esc>', 'q', '<C-c>' },
        default = function(register)
          register('h', require('smart-splits').resize_left, { desc = 'Resize left' })
          register('j', require('smart-splits').resize_down, { desc = 'Resize down' })
          register('k', require('smart-splits').resize_up, { desc = 'Resize up' })
          register('l', require('smart-splits').resize_right, { desc = 'Resize right' })
          register('<Left>', require('smart-splits').resize_left, { desc = 'Resize left' })
          register('<Down>', require('smart-splits').resize_down, { desc = 'Resize down' })
          register('<Up>', require('smart-splits').resize_up, { desc = 'Resize up' })
          register('<Right>', require('smart-splits').resize_right, { desc = 'Resize right' })
        end,
      })
      local nvim_get_visible_wins = function()
        local visible_wins = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local win_config = vim.api.nvim_win_get_config(win)
          if vim.api.nvim_win_is_valid(win) and win_config.relative == '' then
            table.insert(visible_wins, win)
          end
        end
        return visible_wins
      end
      vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('winresize-enter', {}),
        pattern = 'SubmodeEnterPost',
        callback = function(env)
          if env.data.name == 'WinResize' then
            if #nvim_get_visible_wins() > 1 then
              vim.notify 'Use { h, j, k, l } or { <Left>, <Down>, <Up>, <Right> } to resize the window'
            else
              vim.notify 'Only one window is being used'
              submode.leave()
              -- stylua: ignore
              vim.defer_fn(function() vim.cmd [[echon '']] end, 2500)
            end
          end
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('winresize-leave', {}),
        pattern = 'SubmodeLeavePost',
        callback = function(env)
          if env.data.name == 'WinResize' then
            vim.cmd [[echon '']]
          end
        end,
      })
    end,
  },
}
