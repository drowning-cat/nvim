local wins = require 'misc.wins'

-- Vim tabs
vim.keymap.set('n', 'gC', '<cmd>tabclose<CR>', { desc = 'Vimtab [C]lose' })
vim.keymap.set('n', 'gN', '<cmd>tabnew<CR>', { desc = 'Vimtab [N]ew' })

-- Create
vim.keymap.set('n', '<leader>V', '<cmd>vnew<CR>', { desc = 'Open [V]ertical window' })
vim.keymap.set('n', '<leader>H', '<cmd>new<CR>', { desc = 'Open [H]orizontal window' })

vim.keymap.set('n', '<leader>w', '<C-w>', { noremap = true })
-- Close
vim.keymap.set('n', '<leader>wq', wins.close, { desc = 'Close the window' })
-- Swap
-- stylua: ignore start
vim.keymap.set('n', '<leader>wH', function() wins.swap_buf 'h' end, { desc = 'Swap with buffer left' })
vim.keymap.set('n', '<leader>wJ', function() wins.swap_buf 'j' end, { desc = 'Swap with buffer down' })
vim.keymap.set('n', '<leader>wK', function() wins.swap_buf 'k' end, { desc = 'Swap with buffer up' })
vim.keymap.set('n', '<leader>wL', function() wins.swap_buf 'l' end, { desc = 'Swap with buffer right' })
-- stylua: ignore end
-- Navigate
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')
vim.keymap.set('n', '<C-Left>', '<C-w>h')
vim.keymap.set('n', '<C-Down>', '<C-w>j')
vim.keymap.set('n', '<C-Up>', '<C-w>k')
vim.keymap.set('n', '<C-Right>', '<C-w>l')
-- Swap
-- stylua: ignore start
vim.keymap.set('n', '<C-S-h>', function() wins.swap_buf 'h' end)
vim.keymap.set('n', '<C-S-j>', function() wins.swap_buf 'j' end)
vim.keymap.set('n', '<C-S-k>', function() wins.swap_buf 'k' end)
vim.keymap.set('n', '<C-S-l>', function() wins.swap_buf 'l' end)
vim.keymap.set('n', '<C-S-Left>', function() wins.swap_buf 'h' end)
vim.keymap.set('n', '<C-S-Down>', function() wins.swap_buf 'j' end)
vim.keymap.set('n', '<C-S-Up>', function() wins.swap_buf 'k' end)
vim.keymap.set('n', '<C-S-Right>', function() wins.swap_buf 'l' end)
-- stylua: ignore end

return {
  {
    'romgrk/barbar.nvim',
    lazy = false,
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
      { '<leader><Tab>', desc = 'Tab' },
      { '<leader><Tab><Tab>', desc = 'VimTab' },
      {
        '<leader><Tab>t',
        function()
          local buffers = require('barbar.state').buffers
          if not vim.tbl_isempty(buffers) then
            vim.o.showtabline = vim.o.showtabline ~= 0 and 0 or 2
          end
        end,
        desc = 'Tab [T]oggle',
      },
      { '[b', '<cmd>BufferPrevious<CR>', desc = '[B]uffer next' },
      { ']b', '<cmd>BufferNext<CR>', desc = '[B]uffer prev' },
      { '<leader>bd', '<cmd>BufferClose<CR>', desc = '[B]uffer [d]elete' },
      { '<leader><Tab>h', '<cmd>BufferPrevious<CR>', desc = 'Tab select left' },
      { '<leader><Tab>l', '<cmd>BufferNext<CR>', desc = 'Tab select right' },
      { '<leader><Tab>k', '<cmd>BufferMoveNext<CR>', desc = 'Tab move next' },
      { '<leader><Tab>j', '<cmd>BufferMovePrevious<CR>', desc = 'Tab move prev' },
      { '<leader><Tab>p', '<cmd>BufferPin<CR>', desc = 'Tab [p]in' },
      { '<leader><Tab>q', '<cmd>BufferClose<CR>', desc = 'Tab [q]uit' },
      { '<leader><Tab>w', '<cmd>BufferCloseAllButCurrentOrPinned<CR>', desc = 'Tab [W]ipeout tabs' },
      {
        '<leader><Tab>c',
        function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_get_name(buf) == '' then
              vim.api.nvim_buf_delete(buf, {})
            end
          end
        end,
        desc = 'Tab [c]lean unnamed buffers',
      },
      { '<leader><Tab>1', '<Cmd>BufferGoto 1<CR>', desc = 'Tab goto [1]' },
      { '<leader><Tab>2', '<Cmd>BufferGoto 2<CR>', desc = 'Tab goto [2]' },
      { '<leader><Tab>3', '<Cmd>BufferGoto 3<CR>', desc = 'Tab goto [3]' },
      { '<leader><Tab>4', '<Cmd>BufferGoto 4<CR>', desc = 'Tab goto [4]' },
      { '<leader><Tab>5', '<Cmd>BufferGoto 5<CR>', desc = 'Tab goto [5]' },
      { '<leader><Tab>6', '<Cmd>BufferGoto 6<CR>', desc = 'Tab goto [6]' },
      { '<leader><Tab>7', '<Cmd>BufferGoto 7<CR>', desc = 'Tab goto [7]' },
      { '<leader><Tab>8', '<Cmd>BufferGoto 8<CR>', desc = 'Tab goto [8]' },
      { '<leader><Tab>9', '<Cmd>BufferGoto 9<CR>', desc = 'Tab goto [9]' },
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
        -- stylua: ignore
        default = function()
          reg('WinResize', 'h', function() wins.resize 'h' end, { desc = 'Resize left' })
          reg('WinResize', 'j', function() wins.resize 'j' end, { desc = 'Resize down' })
          reg('WinResize', 'k', function() wins.resize 'k' end, { desc = 'Resize up' })
          reg('WinResize', 'l', function() wins.resize 'l' end, { desc = 'Resize right' })
          reg('WinResize', '<Left>', function() wins.resize 'h' end, { desc = 'Resize left' })
          reg('WinResize', '<Down>', function() wins.resize 'j' end, { desc = 'Resize down' })
          reg('WinResize', '<Up>', function() wins.resize 'k' end, { desc = 'Resize up' })
          reg('WinResize', '<Right>', function() wins.resize 'l' end, { desc = 'Resize right' })
        end,
      })
    end,
  },
}
