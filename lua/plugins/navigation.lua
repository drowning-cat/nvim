local W = vim.u.win

-- Vim tabs
vim.keymap.set('n', 'gC', function()
  local used_wins = {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if tab ~= vim.api.nvim_get_current_tabpage() then
      for _, tab_win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        table.insert(used_wins, tab_win)
      end
    end
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if not vim.tbl_contains(used_wins, win) then
      vim.cmd.bdelete(vim.api.nvim_win_get_buf(win))
    end
  end
end, { desc = 'Vimtab [C]lose' })
vim.keymap.set('n', 'gN', '<cmd>tabnew<CR>', { desc = 'Vimtab [N]ew' })

-- Create
vim.keymap.set('n', '<leader>V', '<cmd>vnew<CR>', { desc = 'Open [V]ertical window' })
vim.keymap.set('n', '<leader>H', '<cmd>new<CR>', { desc = 'Open [H]orizontal window' })

-- Close
vim.keymap.set('n', '<C-q>', W.close, { desc = 'Close the window' })

-- Navigate
local winmove = function(norm, float)
  if vim.api.nvim_win_get_config(0).relative ~= '' then
    vim.cmd.wincmd(float)
  else
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(norm)
    if win == vim.api.nvim_get_current_win() then
      vim.cmd.wincmd(float)
    end
  end
end
-- stylua: ignore start
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', function() winmove('j', 'w') end)
vim.keymap.set('n', '<C-k>', function() winmove('k', 'W') end)
vim.keymap.set('n', '<C-l>', '<C-w>l')
vim.keymap.set('n', '<C-Left>', '<C-h>', { remap = true })
vim.keymap.set('n', '<C-Down>', '<C-j>', { remap = true })
vim.keymap.set('n', '<C-Up>', '<C-k>', { remap = true })
vim.keymap.set('n', '<C-Right>', '<C-l>', { remap = true })
-- stylua: ignore end

-- Swap
-- stylua: ignore start
vim.keymap.set('n', '<C-S-h>', function() W.swap_buf 'h' end)
vim.keymap.set('n', '<C-S-j>', function() W.swap_buf 'j' end)
vim.keymap.set('n', '<C-S-k>', function() W.swap_buf 'k' end)
vim.keymap.set('n', '<C-S-l>', function() W.swap_buf 'l' end)
vim.keymap.set('n', '<C-S-Left>', function() W.swap_buf 'h' end)
vim.keymap.set('n', '<C-S-Down>', function() W.swap_buf 'j' end)
vim.keymap.set('n', '<C-S-Up>', function() W.swap_buf 'k' end)
vim.keymap.set('n', '<C-S-Right>', function() W.swap_buf 'l' end)
-- stylua: ignore end

return {
  {
    'declancm/maximize.nvim',
    -- stylua: ignore
    keys = {
      { '<C-f>', function() require('maximize').toggle() end, desc = 'Toggle [F]ullscreen' },
    },
  },
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
    'echasnovski/mini.clue',
    lazy = false,
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'snacks_*',
        callback = function(event)
          MiniClue.enable_buf_triggers(event.buf)
        end,
      })
    end,
    config = function()
      local miniclue = require 'mini.clue'
      local config = miniclue.config
      local reg = function(mode, prefix, lhs, rhs, opts)
        local keys = prefix .. lhs
        local clue = {
          mode = mode,
          keys = keys,
        }
        if opts.postkeys == false then
          clue.postkeys = nil
        else
          clue.postkeys = opts.postkeys or prefix
        end
        table.insert(config.clues, clue)
        opts.postkeys = nil
        vim.keymap.set(mode, keys, rhs, opts)
      end

      for _, prefix in ipairs { '<C-w>r', '<C-w><C-r>' } do
        vim.keymap.set('n', prefix, '<nop>')
        table.insert(config.triggers, { mode = 'n', keys = prefix })
        -- stylua: ignore start
        reg('n', prefix, 'q', '<nop>', { postkeys = false, desc = 'Quit' })
        reg('n', prefix, 'h', function() W.resize 'h' end, { desc = 'Resize left' })
        reg('n', prefix, 'j', function() W.resize 'j' end, { desc = 'Resize down' })
        reg('n', prefix, 'k', function() W.resize 'k' end, { desc = 'Resize up' })
        reg('n', prefix, 'l', function() W.resize 'l' end, { desc = 'Resize right' })
        reg('n', prefix, 'H', '<C-w>h', { remap = true, desc = 'Move left' })
        reg('n', prefix, 'J', '<C-w>j', { remap = true, desc = 'Move down' })
        reg('n', prefix, 'K', '<C-w>k', { remap = true, desc = 'Move up' })
        reg('n', prefix, 'L', '<C-w>l', { remap = true, desc = 'Move right' })
      end

      miniclue.setup(config)
    end,
  },
}
