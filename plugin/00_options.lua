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

vim.g.session_center = false
vim.g.session_ft_ignore = {
  "gitcommit",
  "gitrebase",
}

vim.g.root_markers = {
  ".git",
  "Makefile",
  "package.json",
}

vim.g.project_maxdepth = 3
vim.g.project_dirs = {
  "~/Projects",
}
vim.g.project_ignore = {
  "node_modules",
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

vim.g.format_on_save = true

local buf_name = function(buf)
  return vim.api.nvim_buf_get_name(buf or 0)
end

---@type table<string, fun(line1:integer,line2:integer):FormatBufOpts|FormatBufOpts[]>
local formatters = {
  stylua = function()
    return { cmd = { "stylua", "--indent-type=Spaces", "--indent-width=2", "--stdin-filepath", buf_name(), "-" } }
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
