-- Set <Space> as the leader key
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Make line numbers default
vim.o.number = true
vim.o.relativenumber = true

-- Number of spaces tabs count for
vim.o.tabstop = 2
vim.o.shiftwidth = 0

-- Confirm on save instead of fail
vim.o.confirm = true

-- Enable mouse mode, can be useful for resizing splits
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Backup files
-- Double slash to build file name from the complete path to the file with all path separators changed to percent '%' signs
vim.o.backupdir = vim.fn.stdpath 'state' .. '/backup'
vim.o.backup = true

-- Indentation for every wrapped line
vim.o.breakindent = false

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimum number of screen lines to keep above and below the cursor,
-- sometimes referred to as scroll padding
vim.o.scrolloff = 10

-- Setup the spell checker.
-- Useful keymaps:
--  * zg - add the word to the dictionary
--  * z= - find suggestions for misspelled words
--  * [s - move to the prev misspelled word
--  * ]s - move to the next misspelled word
-- ```sh
--  curl https://ftp.nluug.nl/pub/vim/runtime/spell/ru.utf-8.spl -o ~/.local/share/nvim/site/spell/ru.utf-8.spl
--  curl https://ftp.nluug.nl/pub/vim/runtime/spell/ru.utf-8.sug -o ~/.local/share/nvim/site/spell/ru.utf-8.sug
-- ```
vim.o.spelllang = 'en_us,ru'
vim.o.spell = true

-- Prevent ^F from being printed
local indentexpr = vim.bo.indentexpr
if indentexpr == '' then
  vim.bo.indentexpr = 'v:lua.__indentexpr_unknown()'
end

-- Prevent certain keymaps from being printed:
local unmap_insert = function(lhs)
  vim.keymap.set({ 'i', 'c' }, lhs, '<nop>')
end
for i = 1, 12 do
  unmap_insert(string.format('<F%i>', i))
  unmap_insert(string.format('<C-F%i>', i))
end
for _, key in ipairs { 'C-z', 'C-b', 'C-_', 'C-\\', 'S-Del' } do
  unmap_insert(string.format('<%s>', key))
end

-- Move virtual lines instead of physical
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Add undo breakpoint
vim.keymap.set('i', ',', ',<C-g>u')
vim.keymap.set('i', '.', '.<C-g>u')
vim.keymap.set('i', ';', ';<C-g>u')

-- Add empty lines in normal mode
vim.keymap.set({ 'n', 'v' }, '<leader>O', "<cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>", { desc = 'Add blank line above' })
vim.keymap.set({ 'n', 'v' }, '<leader>o', "<cmd>call append(line('.'),     repeat([''], v:count1))<CR>", { desc = 'Add blank line below' })

-- Mode independent search navigation
vim.keymap.set('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next search result' })
vim.keymap.set('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
vim.keymap.set('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
vim.keymap.set('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev search result' })
vim.keymap.set('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })
vim.keymap.set('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })

-- Additional insert mode motions
vim.keymap.set('i', '<C-S-h>', '<Left>', { noremap = true })
vim.keymap.set('i', '<C-S-j>', '<Down>', { noremap = true })
vim.keymap.set('i', '<C-S-k>', '<Up>', { noremap = true })
vim.keymap.set('i', '<C-S-l>', '<Right>', { noremap = true })
vim.keymap.set('i', '<C-h>', '<nop>')
vim.keymap.set('i', '<C-j>', '<nop>') -- Move completion down
vim.keymap.set('i', '<C-k>', '<nop>') -- Move completion up
vim.keymap.set('i', '<C-l>', '<nop>')

-- Fast commenting below or above
vim.keymap.set('n', 'gcj', 'o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add comment below' })
vim.keymap.set('n', 'gck', 'O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add comment above' })

-- Save file
vim.keymap.set({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = '[S]ave file' })
-- Quit all
vim.keymap.set('n', '<A-Esc>', '<cmd>qa<cr>', { desc = '[Q]uit All' })

-- Remap some of the default insert commands:
--  * <C-d> is used to scroll the completion menu down
vim.keymap.set('i', '<C-S-Tab>', '<C-d>', { noremap = true })
vim.keymap.set('i', '<C-Tab>', '<C-t>', { noremap = true })
vim.keymap.set('i', '<C-d>', '<nop>')
vim.keymap.set('i', '<C-t>', '<nop>')
--  * <C-u> is used to scroll the completion menu up
--  * <C-u> is also too close to <C-y>, which could lead to accidental presses
vim.keymap.set({ 'i', 'c' }, '<C-x>', '<C-u>', { noremap = true })
vim.keymap.set({ 'i', 'c' }, '<C-u>', '<nop>')

-- Clear highlights on search when pressing <ESC>
-- Overridden by multicursor.nvim
vim.keymap.set('n', '<ESC>', '<cmd>nohlsearch<CR>')

-- Exit terminal mode in the builtin terminal with a bit easier shortcut
-- NOTE: This may not work in all terminal emulators/tmux/etc
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Sync clipboard between OS and Neovim
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<leader>Y', '"+Y', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<leader>c', '"+c', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<leader>C', '"+C', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<leader>d', '"+d', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<leader>D', '"+D', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<leader>p', '"+p', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<leader>P', '"+P', { noremap = true })

-- Copy contents of the unnamed register (") to system clipboard (+)
vim.keymap.set('n', 'y=', function()
  local copy = vim.fn.getreg '"'
  if copy ~= '' then
    vim.fn.setreg('+', copy)
    vim.notify('Copied to clipboard:\n' .. copy)
  end
end)

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

local function augroup(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

-- Add timestamp as extension for backup files
vim.api.nvim_create_autocmd('BufWritePre', {
  group = augroup 'timestamp_backupext',
  desc = 'Add timestamp to backup extension',
  pattern = '*',
  callback = function()
    vim.o.backupext = '-' .. vim.fn.strftime '%Y%m%d%H%M'
  end,
})

-- Highlight when copying text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup 'highlight_yank',
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup 'checktime',
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd 'checktime'
    end
  end,
})

-- Resize splits if window got resized
vim.api.nvim_create_autocmd('VimResized', {
  group = augroup 'resize_splits',
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd 'tabdo wincmd ='
    vim.cmd('tabnext ' .. current_tab)
  end,
})

-- Close some filetypes with `q`
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'close_with_q',
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    'dbout',
    'gitsigns-blame',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'qf',
    'query',
    'spectre_panel',
    'startuptime',
    'tsplayground',
  },
  callback = function(event)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(event.buf) then
        return
      end
      vim.bo[event.buf].buflisted = false
      vim.keymap.set('n', 'q', function()
        vim.cmd 'close'
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, { buffer = event.buf, silent = true, desc = 'Quit buffer' })
    end)
  end,
})

-- Make it easier to close man-files when opened inline
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'man_unlisted',
  pattern = 'man',
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- Wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'wrap_spell',
  pattern = { 'text', 'plaintex', 'typst', 'gitcommit', 'markdown' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd('BufWritePre', {
  group = augroup 'auto_create_dir',
  callback = function(event)
    if event.match:match '^%w%w+:[\\/][\\/]' then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

-- Start `q:` with insert mode
vim.api.nvim_create_autocmd('CmdwinEnter', {
  group = augroup 'q_startinsert',
  pattern = ':',
  command = 'startinsert',
})

-- Smart quit: start
local ft_autoclose = { 'snacks_', 'dapui_', 'dap-repl', 'qf' }
local ft_autoclose_ignore = { 'snacks_dashboard' }

local list_wins = function()
  local all, close, rest = vim.api.nvim_list_wins(), {}, {}
  for _, win in ipairs(all) do
    local config = vim.api.nvim_win_get_config(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local wininfo = vim.fn.getwininfo(win)[1]
    local is_ignore = vim.iter(ft_autoclose_ignore):any(function(pat)
      return string.match(vim.bo[buf].ft, pat)
    end)
    local is_ft = vim.iter(ft_autoclose):any(function(pat)
      return string.match(vim.bo[buf].ft, pat)
    end)
    local is_float = config.relative ~= ''
    local is_qf = wininfo.quickfix == 1 or wininfo.loclist == 1
    if not is_ignore and (is_ft or is_float or is_qf) then
      table.insert(close, win)
    else
      table.insert(rest, win)
    end
  end
  return all, rest, close
end

vim.api.nvim_create_autocmd('QuitPre', {
  group = augroup 'smart_quit',
  callback = function()
    local _, wins, close = list_wins()
    local cur_win = vim.api.nvim_get_current_win()
    if #wins ~= 1 then
      return
    end
    if vim.list_contains(close, cur_win) then
      return
    end
    if vim.list_contains(close, cur_win) then
      -- stylua: ignore
      vim.defer_fn(function() pcall(vim.cmd.quit) end, 100)
    end
    for _, win in ipairs(close) do
      pcall(vim.api.nvim_win_close, win, true)
    end
  end,
})
-- Smart quit: end

local util = require 'misc.util'
util.setup()

-- Automatically changes to the approximate root folder
vim.o.autochdir = false -- Disable conflicting option
local chroot = function()
  local root = util.find_root()
  if root then
    vim.fn.chdir(root)
    return root
  end
end
vim.api.nvim_create_user_command('Root', function()
  vim.print(chroot())
end, {})
local aug_root = vim.api.nvim_create_augroup('change_root', {})
vim.api.nvim_create_autocmd('VimEnter', {
  group = aug_root,
  callback = function()
    local farg = vim.fn.argv(0) --[[@as string?]]
    if farg and vim.fn.isdirectory(farg) == 1 then
      vim.schedule(function()
        vim.fn.chdir(vim.fn.fnamemodify(farg, ':p'))
      end)
    end
  end,
})

-- All entries will be installed by `mason-tool-installer`
-- May be extended in other files
vim.g.mason_install = {} --- @type string[]
---@param list string[]
vim.g.mason_install_extend = function(list)
  vim.g.mason_install = vim.list_extend(vim.g.mason_install or {}, list)
  return vim.g.mason_install
end

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

-- Configure and install plugins
--
--  To check the current status of your plugins, run `:Lazy`
--
--  For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
--
require('lazy').setup {
  spec = {
    { 'tpope/vim-sleuth' }, -- Detect tabstop and shiftwidth automatically
    { 'nacro90/numb.nvim', config = true }, -- Peek lines (can be canceled)
    { import = 'plugins' }, -- Import files from `lua/plugins/*.lua`
    { import = 'plugins.snacks' },
  },
  install = {
    colorscheme = { require('misc.save_colors').get_colorscheme 'habamax' },
  },
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
