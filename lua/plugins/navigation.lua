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

    -- Store `vim.opt.foldenable`
    local win_1_folds_enabled = vim.api.nvim_get_option_value('foldenable', { win = win_1 })
    local win_2_folds_enabled = vim.api.nvim_get_option_value('foldenable', { win = win_2 })
    -- Disable `vim.opt.foldenable`
    vim.api.nvim_set_option_value('foldenable', false, { win = win_1 })
    vim.api.nvim_set_option_value('foldenable', false, { win = win_2 })

    -- Store views
    local view_1 = vim.api.nvim_win_call(win_1, vim.fn.winsaveview)
    local view_2 = vim.api.nvim_win_call(win_2, vim.fn.winsaveview)

    -- Swap buffers
    vim.api.nvim_win_set_buf(win_1, buf_2)
    vim.api.nvim_win_set_buf(win_2, buf_1)

    -- Swap `vim.opt.list`
    vim.api.nvim_set_option_value('list', win_1_list, { win = win_2 })
    vim.api.nvim_set_option_value('list', win_2_list, { win = win_1 })

    -- Swap views
    vim.api.nvim_win_call(win_1, function()
      vim.fn.winrestview(view_2)
    end)
    vim.api.nvim_win_call(win_2, function()
      vim.fn.winrestview(view_1)
    end)

    -- Restore `vim.opt.foldenable`
    vim.api.nvim_set_option_value('foldenable', win_1_folds_enabled, { win = win_1 })
    vim.api.nvim_set_option_value('foldenable', win_2_folds_enabled, { win = win_2 })

    if move_cursor == true then
      vim.fn.win_gotoid(win_2)
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

-- Close
vim.keymap.set('n', '<C-q>', function()
  vim.bo.bufhidden = 'delete'
  vim.cmd 'q'
end, { desc = 'Close the window' })

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

return {
  {
    'romgrk/barbar.nvim',
    event = { 'FileType', 'VimEnter' },
    dependencies = {
      'lewis6991/gitsigns.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    opts = {
      animation = false,
      auto_hide = 0,
      exclude_ft = {
        'minifiles',
        'snacks_dashboard',
        'man',
        'qf',
      },
      icons = {
        button = '',
        separator = { left = '', right = '' },
        inactive = { separator = { left = '', right = '' } },
        separator_at_end = false,
      },
      maximum_padding = 3,
    },
    keys = {
      {
        '<leader><Tab><Tab>',
        function()
          local buffers = require('barbar.state').buffers
          if not vim.tbl_isempty(buffers) then
            vim.o.showtabline = vim.o.showtabline ~= 0 and 0 or 2
          end
        end,
        desc = '[T]oggle [T]ab bar',
      },
      { '[b', '<cmd>BufferPrevious<CR>', desc = '[B]uffer next' },
      { ']b', '<cmd>BufferNext<CR>', desc = '[B]uffer prev' },
      { '<leader><Tab>h', '<cmd>BufferPrevious<CR>', desc = '[T]ab select left' },
      { '<leader><Tab>l', '<cmd>BufferNext<CR>', desc = '[T]ab select right' },
      { '<leader><Tab>k', '<cmd>BufferMoveNext<CR>', desc = '[T]ab move next' },
      { '<leader><Tab>j', '<cmd>BufferMovePrevious<CR>', desc = '[T]ab move prev' },
      { '<leader><Tab>p', '<cmd>BufferPin<CR>', desc = '[T]ab [P]in' },
      { '<leader><Tab>q', '<cmd>BufferClose<CR>', desc = '[T]ab [q]uit' },
      { '<leader><Tab>w', '<cmd>BufferCloseAllButCurrentOrPinned<CR>', desc = '[T]ab [w]ipeout tabs' },
      { '<leader><Tab>1', '<Cmd>BufferGoto 1<CR>', desc = 'Tab [1] ' },
      { '<leader><Tab>2', '<Cmd>BufferGoto 2<CR>', desc = 'Tab [2]' },
      { '<leader><Tab>3', '<Cmd>BufferGoto 3<CR>', desc = 'Tab [3]' },
      { '<leader><Tab>4', '<Cmd>BufferGoto 4<CR>', desc = 'Tab [4]' },
      { '<leader><Tab>5', '<Cmd>BufferGoto 5<CR>', desc = 'Tab [5]' },
      { '<leader><Tab>6', '<Cmd>BufferGoto 6<CR>', desc = 'Tab [6]' },
      { '<leader><Tab>7', '<Cmd>BufferGoto 7<CR>', desc = 'Tab [7]' },
      { '<leader><Tab>8', '<Cmd>BufferGoto 8<CR>', desc = 'Tab [8]' },
      { '<leader><Tab>9', '<Cmd>BufferGoto 9<CR>', desc = 'Tab [9]' },
      { '<leader><Tab>0', '<Cmd>BufferLast<CR>', desc = 'Tab last' },
    },
  },

  {
    'declancm/maximize.nvim',
    -- stylua: ignore
    keys = {
      { '<C-f>', function() require('maximize').toggle() end, desc = 'Toggle [F]ullscreen' },
    },
  },

  {
    'pogyomo/submode.nvim',
    keys = { '<C-w>r', '<C-w><C-r>' },
    config = function()
      -- Resize
      require('submode').create('WinResize', {
        mode = 'n',
        enter = { '<C-w>r', '<C-w><C-r>' },
        leave = { '<Esc>', 'q', '<C-c>' },
        hook = {
          on_enter = function()
            vim.u.notify 'Use { h, j, k, l } or { <Left>, <Down>, <Up>, <Right> } to resize the window'
          end,
          on_leave = function()
            vim.u.notify('', { force = false })
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
