if vim.fn.has("nvim-0.13") == 0 then
  return vim.notify("Install Neovim 0.12+", vim.log.levels.ERROR)
end

-- Options

vim.o.exrc = true

vim.g.mapleader = " "

vim.o.number = true
vim.o.relativenumber = true

vim.o.signcolumn = "yes"

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitbelow = true
vim.o.splitright = true
vim.o.tabclose = "uselast"

vim.o.confirm = true

vim.o.breakindent = true
vim.o.wrap = false

vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 2
vim.o.softtabstop = -1

vim.o.foldmethod = "indent"
vim.o.foldtext = ""
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldnestmax = 10

vim.o.undofile = true
vim.o.undolevels = 10000

vim.o.ignorecase = true
vim.o.smartcase = true

vim.opt.iskeyword:append("-")

vim.o.list = true
vim.o.listchars = "tab:▷ ,trail:·,nbsp:␣"

vim.o.spell = true
vim.o.spelllang = "en_us,ru"
vim.o.spelloptions = "camel"

vim.o.backup = true
vim.o.backupdir = vim.fn.stdpath("state") .. "/backup"

vim.api.nvim_set_hl(0, "StatusLineModified", { link = "WarningMsg" })
vim.o.statusline = string.gsub(vim.o.statusline, "%%m", "%%#StatusLineModified#%%m%%*")

-- Plugin options

vim.g.session_directory = vim.fn.stdpath("state") .. "/sessions"
vim.g.session_close_name = {
  "^nvim%-pack://",
}
vim.g.session_close_ft = {
  "gitcommit",
  "gitrebase",
}

vim.g.root_markers = {
  ".git",
  "lua",
  "Makefile",
  "package.json",
  "hyprland.conf",
}

vim.g.project_maxdepth = 3
vim.g.project_dirs = {
  "~/Projects",
}
vim.g.project_ignore = {
  "node_modules",
}

vim.g.cycle_config = {
  { words = { "true", "false" } },
  { words = { "True", "False" }, pat = "%f[%u]()%f[%W]" },
  { words = { "left", "right" } },
  { words = { "Left", "Right" }, pat = "%f[%u]()%f[%W]" },
  { words = { "up", "down" } },
  { words = { "Up", "Down" }, pat = "%f[%u]()%f[%W]" },
  { words = { "and", "or" } },
  { words = { "get", "set" } },
  { words = { "&&", "||" }, pat = "()" },
  { words = { "yes", "no", "maybe" } },
  { words = { "on", "off" } },
  { words = { "stylua: ignore start", "stylua: ignore end", "stylua: ignore" }, pat = "()" },
  { words = { "start", "end" } },
  { words = { "now", "later" } },
  { words = { "keep", "force" } },
  { words = { "NOTE", "WARN", "ERROR" } },
}

vim.g.ts_auto_install = true
vim.g.ts_install = {
  "json",
  "lua",
  "luadoc",
  "python",
  "query",
  "toml",
  "yaml",
}

vim.g.mason_install = {
  "delve",
  "deno",
  "emmylua_ls",
  "gopls",
  "lua-language-server",
  "markdownlint",
  "prettier",
  "ruff",
  "selene",
  "shfmt",
  "stylua",
  "ts_query_ls",
}

vim.g.lsp_lightbulb = false
vim.g.lsp_enable = {
  "basedpyright",
  "gopls",
  "lua_ls",
  "ts_query_ls",
}

vim.g.linters_by_ft = {
  lua = { "selene" },
  markdown = { "markdownlint" },
}

vim.g.format_on_save = false

---@type table<string, Formatter>
vim.g.formatters = {
  prettier = function(ctx)
    return { cmd = { "prettier", "--stdin-filepath", ctx.stdin_path } }
  end,
  ruff = function(ctx)
    return {
      { cmd = { "ruff", "check", "--select=I", "--fix", "--stdin-filename", ctx.stdin_path, "-" } },
      { cmd = { "ruff", "format", "--stdin-filename", ctx.stdin_path, "-" } },
    }
  end,
  shfmt = function()
    return { cmd = { "shfmt", "--indent=2", "-" } }
  end,
  stylua = function(ctx)
    return { cmd = { "stylua", "--search-parent-directories", "--stdin-filepath", ctx.stdin_path, "-" } }
  end,
}

vim.g.formatters_by_ft = {
  ["javascript"] = vim.g.formatters["prettier"],
  ["javascriptreact"] = vim.g.formatters["prettier"],
  ["json"] = vim.g.formatters["prettier"],
  ["jsonc"] = vim.g.formatters["prettier"],
  ["lua"] = vim.g.formatters["stylua"],
  ["markdown"] = vim.g.formatters["prettier"],
  ["python"] = vim.g.formatters["ruff"],
  ["scss"] = vim.g.formatters["prettier"],
  ["sh"] = vim.g.formatters["shfmt"],
  ["typescript"] = vim.g.formatters["prettier"],
  ["typescriptreact"] = vim.g.formatters["prettier"],
  ["yaml"] = vim.g.formatters["prettier"],
}

-- Setup

require("vim._core.ui2").enable({
  msg = {
    targets = {
      ["^lsp"] = "msg",
    },
  },
})
require("util.root").setup()

-- Autocmds

vim.api.nvim_create_autocmd({ "TextYankPost", "TextPutPost" }, {
  group = vim.api.nvim_create_augroup("config/yank_hl", { clear = true }),
  desc = "Highlight yanking text",
  callback = function()
    vim.hl.hl_op()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  group = vim.api.nvim_create_augroup("config/help_keymaps", { clear = true }),
  desc = "Adjust mouse keymaps in `help` buffers",
  callback = function(e)
    local buf_map = function(modes, lhs, rhs, opts) ---@param opts? vim.keymap.set.Opts
      opts = opts or {}
      opts.buf = e.buf
      vim.keymap.set(modes, lhs, rhs, opts)
    end
    buf_map("n", "<2-LeftMouse>", "viw", { desc = "Select word" })
    buf_map("n", "<C-LeftMouse>", "<LeftMouse><C-]>", { remap = true, desc = "Jump tag" })
  end,
})

-- Commands

vim.api.nvim_create_user_command("PackClean", function()
  local names = {}
  for _, p in ipairs(vim.pack.get()) do
    if not p.active then
      table.insert(names, p.spec.name)
    end
  end
  vim.pack.del(names)
end, {})

-- Keymaps

vim.keymap.set("x", "p", "P")
vim.keymap.set("x", "P", "p")

vim.keymap.set("n", "<Leader>R", function()
  if vim.bo.buftype == "" and vim.bo.modifiable and not vim.bo.readonly then
    vim.cmd("confirm write | restart")
  else
    vim.cmd("restart")
  end
end, { desc = "Restart" })

vim.keymap.set("n", "<Leader>w", "<Cmd>w<Enter>", { desc = "Write" })
vim.keymap.set("n", "<Leader>W", "<Cmd>wall<Enter>", { desc = "Write all" })

vim.keymap.set("i", "<C-Enter>", "<Enter><Up><End>", { desc = "Anchored enter" })

vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<Enter>", { desc = "Clear hlsearch" })

vim.keymap.set({ "n", "i" }, "<C-S-h>", "<Left>", { desc = "Cursor left" })
vim.keymap.set({ "n", "i" }, "<C-S-j>", "<Down>", { desc = "Cursor down" })
vim.keymap.set({ "n", "i" }, "<C-S-k>", "<Up>", { desc = "Cursor up" })
vim.keymap.set({ "n", "i" }, "<C-S-l>", "<Right>", { desc = "Cursor right" })

vim.keymap.set("o", "C", "gc", { remap = true, desc = "Comment-block textobject" })

vim.keymap.set("n", "gA", "<Cmd>tab split<Enter>", { desc = "Add tab" })
vim.keymap.set("n", "gC", "<Cmd>tabclose<Enter>", { desc = "Close tab" })

vim.keymap.set("n", "[p", '<Cmd>exe "put! " . v:register<Enter>', { desc = "Paste above" })
vim.keymap.set("n", "]p", '<Cmd>exe "put "  . v:register<Enter>', { desc = "Paste below" })

vim.keymap.set("n", "[u", "g-", { desc = "Undo" })
vim.keymap.set("n", "]u", "g+", { desc = "Redo" })
local huge = 2 ^ 31 - 1
vim.keymap.set("n", "[U", huge .. "g-", { desc = "Undo first" })
vim.keymap.set("n", "]U", huge .. "g+", { desc = "Redo last" })

-- See https://github.com/neovim/neovim/discussions/34076
local copy_last = function()
  local copy = vim.fn.getreg('"')
  if copy == "" then
    return
  end
  vim.fn.setreg("+", copy)
  local msg = ""
  local _, ln = string.gsub(copy, "\n", "")
  if ln > 0 then
    msg = string.format('%d %s yanked into "+', ln, ln > 1 and "lines" or "line")
  else
    local ch = vim.fn.strdisplaywidth(copy)
    msg = string.format('%d %s yanked into "+', ch, ch > 1 and "chars" or "char")
  end
  vim.api.nvim_echo({ { msg } }, false, {})
end
-- stylua: ignore
vim.keymap.set("n", "gy", function() copy_last() end, { desc = "Yank last into clipboard" })

-- Plugins

vim.cmd.packadd("nvim.undotree")

local pack = require("util.pack")

pack.add({
  { src = "https://github.com/tpope/vim-sleuth" },
})

local mason_install = vim.nonnil(vim.g.mason_install, {})

pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
})

pack.plug(function()
  require("mason").setup()
  local mason_available = require("mason-registry").get_installed_package_names()
  local mason_rest = {}
  for _, inst in ipairs(mason_install) do
    if not vim.list_contains(mason_available, inst) then
      table.insert(mason_rest, inst)
    end
  end
  if #mason_rest > 0 then
    vim.cmd("MasonInstall " .. table.concat(mason_rest, " "))
  end
end)

-- NOTE: See `plugin/` folder
