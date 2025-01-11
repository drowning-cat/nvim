-- Set <Space> as the leader key
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim
-- vim.schedule(function()
--   vim.opt.clipboard = 'unnamedplus'
-- end)
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y')
vim.keymap.set({ 'n', 'v' }, '<leader>Y', '"+Y')
vim.keymap.set({ 'n', 'v' }, '<leader>c', '"+c')
vim.keymap.set({ 'n', 'v' }, '<leader>C', '"+C')
vim.keymap.set({ 'n', 'v' }, '<leader>d', '"+d')
vim.keymap.set({ 'n', 'v' }, '<leader>D', '"+D')
vim.keymap.set({ 'n', 'v' }, '<leader>p', '"+p')
vim.keymap.set({ 'n', 'v' }, '<leader>P', '"+P')

vim.paste = (function(overridden)
  return function(lines, phase)
    local mode = vim.fn.mode()
    if lines[#lines] == '' then
      table.remove(lines, #lines)
    end
    if mode == 'n' then
      vim.api.nvim_put(lines, 'l', true, false) -- paste
    elseif mode == 'V' then
      vim.fn.execute [[ exe "silent normal! \<Del>" ]] -- Delete selection
      vim.api.nvim_put(lines, 'l', false, false) -- Paste
      local select_end = vim.fn.getpos "']" -- Get selection end-position
      select_end[3] = 0 -- Move cursor to start of line
      vim.fn.setpos('.', select_end)
    else
      overridden(lines, phase)
    end
  end
end)(vim.paste)

-- Highlight when copying text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimum number of screen lines to keep above and below the cursor,
-- sometimes referred to as scroll padding
vim.opt.scrolloff = 10

-- Setup the spell checker.
-- Useful keymaps:
--  * zg - add the word to the dictionary
--  * z= - find suggestions for misspelled words
--  * [s - move to the prev misspelled word
--  * ]s - move to the next misspelled word
-- ```sh
--  mkdir -p ~/.local/share/nvim/site/spell/ru.utf-8.spl
--  curl https://ftp.nluug.nl/pub/vim/runtime/spell/ru.utf-8.spl -o ~/.local/share/nvim/site/spell/ru.utf-8.spl
--  curl https://ftp.nluug.nl/pub/vim/runtime/spell/ru.utf-8.sug -o ~/.local/share/nvim/site/spell/ru.utf-8.sug
-- ```
vim.opt.spelllang = 'en_us,ru'
vim.opt.spell = true

-- Prevent certain keymaps from being printed:
-- stylua: ignore
for _, lhs in ipairs {
  'C-q', 'C-e', 'C-o', 'C-a', 'C-h', 'C-j', 'C-k', 'C-l', 'C-z', 'C-v', 'C-b', 'C-_', 'C-/', 'C-\\', 'S-Del',
  'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12',
  'C-F1', 'C-F2', 'C-F3', 'C-F4', 'C-F5', 'C-F6', 'C-F7', 'C-F8', 'C-F9', 'C-F10', 'C-F11', 'C-F12',
} do
  vim.keymap.set({ 'i', 'c' }, '<' .. lhs .. '>', '<nop>')
end

-- Add empty lines in normal mode
vim.keymap.set('n', '<leader>O', "<cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>", { desc = 'Add blank line above' })
vim.keymap.set('n', '<leader>o', "<cmd>call append(line('.'),     repeat([''], v:count1))<CR>", { desc = 'Add blank line below' })

-- Move selection up or down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { noremap = true })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { noremap = true })

-- Move selection left or right
vim.keymap.set('v', '<', '<gv', { noremap = true })
vim.keymap.set('v', '>', '>gv', { noremap = true })

-- Additional insert motions using
vim.keymap.set('i', '<C-S-h>', '<Left>', { noremap = true })
vim.keymap.set('i', '<C-S-j>', '<Down>', { noremap = true })
vim.keymap.set('i', '<C-S-k>', '<Up>', { noremap = true })
vim.keymap.set('i', '<C-S-l>', '<Right>', { noremap = true })
--
vim.keymap.set('i', '<C-h>', '<Left>', { noremap = true })
vim.keymap.set('i', '<C-j>', '<Down>', { noremap = true })
vim.keymap.set('i', '<C-k>', '<Up>', { noremap = true })
vim.keymap.set('i', '<C-l>', '<Right>', { noremap = true })

-- Default actions in insert mode:
-- + <C-w> - delete word
-- + <C-f> - indent line automatically
-- ~ <C-d> -> <C-S-Tab> - indent line back
-- ~ <C-t> +> <C-Tab>   - indent line forward
-- ~ <C-u> -> <C-x>     - delete text before cursor

-- Remap some of the default insert commands:
--  * <C-d> is used to scroll the completion menu down
vim.keymap.set('i', '<C-S-Tab>', '<C-d>', { noremap = true })
vim.keymap.set('i', '<C-Tab>', '<C-t>', { noremap = true })
--  * <C-u> is used to scroll the completion menu up
--  * <C-u> is also too close to <C-y>, which could lead to accidental presses
vim.keymap.set({ 'i', 'c' }, '<C-x>', '<C-u>', { noremap = true })
vim.keymap.set({ 'i', 'c' }, '<C-u>', '<nop>')

-- Clear highlights on search when pressing <ESC>
-- Overridden by multicursor.nvim
vim.keymap.set('n', '<ESC>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>Q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a bit easier shortcut
-- NOTE: This may not work in all terminal emulators/tmux/etc
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

local list_reset = function()
  -- Sets how neovim will display certain whitespace characters in the editor
  -- Example: tab = '» ', trail = '·', nbsp = '␣'
  vim.opt.list = true
  vim.opt.listchars = { tab = '» ', nbsp = '␣' }
end
list_reset()

local list_toggle = function()
  vim.opt.list = not vim.api.nvim_get_option_value('list', {})
end

--- @class ListcharToggleOptions
--- @field char string
--- @field val_true string
--- @field val_false? string
--- @field force? boolean
---
--- @param opts ListcharToggleOptions
local listchar_toggle = function(opts)
  local char = opts.char
  local val_true = opts.val_true
  local val_false = opts.val_false or nil
  local force = opts.force or nil

  if vim.api.nvim_get_option_value('list', {}) == false then
    list_reset()
  end

  local listchars = vim.opt.listchars:get()
  local true_case = listchars[char] ~= val_true
  if force ~= nil then
    true_case = force
  end
  if true_case then
    vim.opt.listchars:remove { char }
    vim.opt.listchars:append { [char] = val_true }
  else
    vim.opt.listchars:remove { char }
    if val_false then
      vim.opt.listchars:append { [char] = val_false }
    end
  end
end

local listchar_toggle_eol = function()
  listchar_toggle { char = 'eol', val_true = '¶' }
end

local listchar_toggle_space = function()
  listchar_toggle { char = 'trail', val_true = '·' }
  listchar_toggle { char = 'lead', val_true = '·' }
end

vim.keymap.set('n', '<leader>tp', listchar_toggle_eol, { desc = '[T]oggle [P]aragraph (=tle)' })
vim.keymap.set('n', '<leader>tl', list_toggle, { desc = '[T]oggle [L]istchars' })
vim.keymap.set('n', '<leader>tle', listchar_toggle_eol, { desc = '[T]oggle [L]istchar [E]ol' })
vim.keymap.set('n', '<leader>tls', listchar_toggle_space, { desc = '[T]oggle [L]istchar [S]space' })

-- Install `lazy.nvim` plugin manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- All entries will be installed by `mason-tool-installer`
-- May be extended in other files
vim.g.mason_install = {} --- @type string[]

-- Assign utility functions to `vim.u`, `vim.util`
require('utils').setup()

-- Configure and install plugins
--
--  To check the current status of your plugins, run `:Lazy`
--
--  For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
--
require('lazy').setup({
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

  { import = 'plugins' }, -- Import files from `lua/plugins/*.lua`
}, { --- @diagnostic disable-line: missing-fields
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
