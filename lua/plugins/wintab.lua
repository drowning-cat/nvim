local win = require 'custom.win-util'

-- Move
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move focus left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move focus down' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move focus up' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move focus right' })
vim.keymap.set('n', '<C-Left>', '<C-w>h', { desc = 'Move focus left' })
vim.keymap.set('n', '<C-Down>', '<C-w>j', { desc = 'Move focus down' })
vim.keymap.set('n', '<C-Up>', '<C-w>k', { desc = 'Move focus up' })
vim.keymap.set('n', '<C-Right>', '<C-w>l', { desc = 'Move focus right' })

-- Close
vim.keymap.set('n', '<C-q>', win.close, { desc = 'Close the window' })

-- Swap
vim.keymap.set('n', '<C-S-h>', win.fn.swap_buf 'left', { desc = 'Swap with buffer left' })
vim.keymap.set('n', '<C-S-j>', win.fn.swap_buf 'down', { desc = 'Swap with buffer down' })
vim.keymap.set('n', '<C-S-k>', win.fn.swap_buf 'up', { desc = 'Swap with buffer up' })
vim.keymap.set('n', '<C-S-l>', win.fn.swap_buf 'right', { desc = 'Swap with buffer right' })
vim.keymap.set('n', '<C-S-Left>', win.fn.swap_buf 'left', { desc = 'Swap with buffer left' })
vim.keymap.set('n', '<C-S-Down>', win.fn.swap_buf 'down', { desc = 'Swap with buffer down' })
vim.keymap.set('n', '<C-S-Up>', win.fn.swap_buf 'up', { desc = 'Swap with buffer up' })
vim.keymap.set('n', '<C-S-Right>', win.fn.swap_buf 'right', { desc = 'Swap with buffer right' })

return {
  {
    'romgrk/barbar.nvim',
    event = 'VeryLazy',
    dependencies = {
      'lewis6991/gitsigns.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    init = function()
      vim.g.barbar_auto_setup = true
      -- Show empty tabline when loading
      vim.o.tabline = ' '
      vim.o.showtabline = 2
    end,
    opts = {
      animation = false,
      auto_hide = 0,
      exclude_ft = {
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
      { '<leader><Tab>1', '<Cmd>BufferGoto 1<CR>', desc = 'Tab [1]' },
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
      local submode = require 'submode'

      ---@alias RegKey [string, string|function, vim.keymap.set.Opts]
      ---@type table<string, RegKey>
      local reg_state = {}

      ---@type fun(mode: string, lhs: string, rhs: string|function, opts?: vim.keymap.set.Opts)
      local reg = function(mode, lhs, rhs, opts)
        reg_state[mode] = reg_state[mode] or {}
        reg_state[mode][#reg_state[mode] + 1] = { lhs, rhs, opts or {} }
      end

      ---@return integer[]
      local ft_include = { 'snacks_picker_list', 'snacks_picker_input' }
      local leave_bufs = function()
        return vim
          .iter(submode.state.leave_bufs)
          :filter(function(buf)
            return vim.api.nvim_buf_is_valid(buf) and vim.list_contains(ft_include, vim.bo[buf].ft)
          end)
          :totable()
      end

      vim.api.nvim_create_autocmd('User', {
        pattern = 'SubmodeEnterPost',
        callback = function(event)
          local mode = event.data.name ---@type string
          local bufs = leave_bufs()
          ---@param key RegKey
          vim.iter(reg_state[mode]):each(function(key)
            local lhs, rhs, opts = unpack(key)
            submode.set(mode, lhs, rhs, opts)
            for _, buf in ipairs(bufs) do
              submode.set(mode, lhs, rhs, vim.tbl_extend('keep', opts, { buffer = buf }))
            end
          end)
        end,
      })

      vim.api.nvim_create_autocmd('User', {
        pattern = 'SubmodeLeavePre',
        callback = function(event)
          local mode = event.data.name ---@type string
          local bufs = leave_bufs()
          ---@param key RegKey
          vim.iter(reg_state[mode]):each(function(key)
            local lhs, _, _ = unpack(key)
            submode.del(mode, lhs)
            for _, buf in ipairs(bufs) do
              submode.del(mode, lhs, { buffer = buf })
            end
          end)
        end,
      })

      ---Patched resize function to redraw vim.notify messages during statusline resizing
      ---@param dir Direction
      local resize_patched = function(dir)
        return function()
          win.resize(dir)
          vim.cmd 'messages'
        end
      end

      -- Resize
      submode.create('WinResize', {
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
        default = function()
          reg('WinResize', 'h', resize_patched 'left', { desc = 'Resize left' })
          reg('WinResize', 'j', resize_patched 'down', { desc = 'Resize down' })
          reg('WinResize', 'k', resize_patched 'up', { desc = 'Resize up' })
          reg('WinResize', 'l', resize_patched 'right', { desc = 'Resize right' })
          reg('WinResize', '<Left>', resize_patched 'left', { desc = 'Resize left' })
          reg('WinResize', '<Down>', resize_patched 'down', { desc = 'Resize down' })
          reg('WinResize', '<Up>', resize_patched 'up', { desc = 'Resize up' })
          reg('WinResize', '<Right>', resize_patched 'right', { desc = 'Resize right' })
        end,
      })
    end,
  },
}
