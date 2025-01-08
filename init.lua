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
--  - zg - add the word to the dictionary
--  - z= - find suggestions for misspelled words
--  - [s - move to the prev misspelled word
--  - ]s - move to the next misspelled word
vim.opt.spelllang = 'en_us,ru'
vim.opt.spell = true

-- Some command actions in insert mode:
-- <C-w> - delete word
-- <C-u> - delete text before cursor
-- <C-t> - indent line forward
-- <C-d> - indent line back
-- <C-f> - indent line automatically

-- Prevent certain keymaps from being printed:
--
-- stylua: ignore
for _, lhs in ipairs {
  'C-q', 'C-e', 'C-o', 'C-a', 'C-h', 'C-j', 'C-k', 'C-l', 'C-z', 'C-v', 'C-b', 'C-_', 'C-/', 'C-\\', 'S-Del',
  'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12',
  'C-F1', 'C-F2', 'C-F3', 'C-F4', 'C-F5', 'C-F6', 'C-F7', 'C-F8', 'C-F9', 'C-F10', 'C-F11', 'C-F12',
} do
  vim.keymap.set('i', '<' .. lhs .. '>', '<nop>')
end

-- Remap <C-u> to <C-x> because it is too close to <C-y>
vim.keymap.set('i', '<C-x>', '<C-u>', { noremap = true })
vim.keymap.set('i', '<C-u>', '<nop>')

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

-- Highlight when copying text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

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
