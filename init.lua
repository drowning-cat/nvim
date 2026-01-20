if vim.fn.has("nvim-0.12") == 0 then
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
vim.o.listchars = "tab:▷ ,trail:·,nbsp:○"

vim.o.spell = true
vim.o.spelllang = "en_us,ru"
vim.o.spelloptions = "camel"

vim.o.backup = true
vim.o.backupdir = vim.fn.stdpath("state") .. "/backup"

-- Plugin options

vim.g.session_directory = vim.fn.stdpath("state") .. "/sessions"
vim.g.session_center = false
vim.g.session_close_ft = {
  "gitcommit",
  "gitrebase",
}

vim.g.root_markers = {
  ".git",
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

vim.g.ts_install = {
  "bash",
  "c",
  "css",
  "diff",
  "go",
  "html",
  "javascript",
  "json",
  "lua",
  "luadoc",
  "python",
  "toml",
  "tsx",
  "typescript",
  "yaml",
  "zig",
}

vim.g.mason_install = {
  "delve",
  "deno",
  "emmylua_ls",
  "gopls",
  "lua-language-server",
  "prettier",
  "shfmt",
  "stylua",
}

vim.g.lsp_enable = {
  "gopls",
  "lua_ls",
}

vim.g.format_on_save = false

local buf_name = function(buf)
  return vim.api.nvim_buf_get_name(buf or 0)
end

---@type table<string, fun(line1:integer,line2:integer):FormatBufOpts|FormatBufOpts[]>
local formatters = {
  stylua = function()
    return { cmd = { "stylua", "--search-parent-directories", "--stdin-filepath", buf_name(), "-" } }
  end,
  prettier = function()
    return { cmd = { "prettier", "--stdin-filepath", buf_name() } }
  end,
  shfmt = function()
    return { cmd = { "shfmt", "--indent=2", "-" } }
  end,
}

vim.g.formatconf = {
  ["javascript"] = formatters["prettier"],
  ["javascriptreact"] = formatters["prettier"],
  ["json"] = formatters["prettier"],
  ["jsonc"] = formatters["prettier"],
  ["lua"] = formatters["stylua"],
  ["markdown"] = formatters["prettier"],
  ["scss"] = formatters["prettier"],
  ["sh"] = formatters["shfmt"],
  ["typescript"] = formatters["prettier"],
  ["typescriptreact"] = formatters["prettier"],
  ["yaml"] = formatters["prettier"],
}

-- Setup

require("util.root").setup()
require("vim._core.ui2").enable({})

-- Builtin plugins

vim.cmd.packadd("nvim.undotree")

-- Mason

local mason_install = vim.F.if_nil(vim.g.mason_install, {})
local pack = require("util.pack")

pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
})

pack.now(function()
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
