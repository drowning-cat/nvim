local session_directory = vim.nonnil(vim.g.session_directory, vim.fn.getcwd())

vim.g.session_close_ft = vim.nonnil(vim.g.session_close_ft, {})
vim.g.session_close_name = vim.nonnil(vim.g.session_close_name, {})

local save_session = function(name)
  local path = vim.fs.joinpath(session_directory, name)
  vim.fn.mkdir(session_directory, "p")
  vim.cmd.mksession({ vim.fn.fnameescape(path), bang = true })
end

local load_session = function(name)
  name = name or vim.g.LAST_SESSION
  assert(name, "Unable to get session name")
  local path = vim.fs.joinpath(session_directory, name)
  vim.cmd("%bwipeout!")
  vim.cmd.source(vim.fn.fnameescape(path))
  vim.g.LAST_SESSION = name
  -- Center cursor
  vim.cmd('normal! zz"')
end

local util_root = require("util.root")
local find_root = util_root.find_root

local get_root_session = function()
  local root = find_root() or vim.fn.getcwd()
  return (string.gsub(root, "/", "%%"))
end

vim.api.nvim_create_user_command("Save", function()
  save_session(get_root_session())
  vim.g.session_auto_save = false
end, {})

vim.api.nvim_create_user_command("Load", function()
  load_session(get_root_session())
end, {})

vim.api.nvim_create_user_command("Last", function()
  load_session()
end, {})

-- Setup

local au_load = vim.api.nvim_create_augroup("session_load", { clear = true })
local au_save = vim.api.nvim_create_augroup("session_save", { clear = true })

if vim.fn.argc() == 0 then
  local is_manpage = vim.iter(vim.v.argv):find(function(arg)
    return arg == "+Man!"
  end)
  -- NOTE: Autoload session
  if not vim.v.startreason == "restart" and not is_manpage and vim.bo.buftype == "" then
    vim.cmd("silent! Load")
  end
  -- NOTE: Ask to open Git conflict files
  vim.system({ "git", "diff", "--relative", "--name-only", "--diff-filter=U" }, {}, function(out)
    if out.code == 0 then
      vim.schedule(function()
        local files = vim.split(out.stdout or "", "\n", { trimempty = true })
        if vim.tbl_isempty(files) then
          return
        end
        local abs_files = vim.tbl_map(vim.fs.abspath, files)
        if vim.fn.confirm("Open conflict files?", "&Yes\n&No", 1) ~= 1 then
          return
        end
        vim.cmd("silent tabonly")
        for _, file in ipairs(abs_files) do
          vim.cmd.tabedit(vim.fn.fnameescape(file))
        end
        vim.cmd.tabclose(1)
      end)
    end
  end)
end

local should_close = function(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.bo[buf].ft
  if vim.list_contains(vim.g.session_close_ft or {}, ft) then
    return true
  end
  local buf_name = vim.api.nvim_buf_get_name(buf)
  for _, pat in ipairs(vim.g.session_close_name or {}) do
    if string.match(buf_name, pat) then
      return true
    end
  end
  return false
end

vim.api.nvim_create_autocmd("SessionLoadPost", {
  group = au_load,
  desc = "Filter windows after session load",
  callback = vim.schedule_wrap(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(win) then
        if should_close(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end
  end),
})

vim.api.nvim_create_autocmd("VimLeave", {
  group = au_save,
  desc = "Save session on exit",
  callback = function()
    vim.cmd("silent! Save")
  end,
})
