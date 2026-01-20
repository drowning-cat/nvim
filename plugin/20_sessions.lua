local session_directory = vim.F.if_nil(vim.g.session_directory, vim.fn.getcwd())

vim.g.session_center = vim.F.if_nil(vim.g.session_center, false)
vim.g.session_auto_load = vim.F.if_nil(vim.g.session_auto_load, true)
vim.g.session_auto_save = vim.F.if_nil(vim.g.session_auto_save, true)
vim.g.session_close_ft = vim.F.if_nil(vim.g.session_close_ft, {})

_G.save_session = function(name)
  local path = vim.fs.joinpath(session_directory, name)
  vim.fn.mkdir(session_directory, "p")
  vim.cmd.mksession({ vim.fn.fnameescape(path), bang = true })
end

_G.load_session = function(name)
  name = name or vim.g.LAST_SESSION
  assert(name, "Unable to get session name")
  local path = vim.fs.joinpath(session_directory, name)
  vim.cmd("%bdelete!") -- %bwipeout!
  vim.cmd.source(vim.fn.fnameescape(path))
  vim.g.LAST_SESSION = name
  if vim.g.session_center then
    vim.cmd('normal! zz"')
  end
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

vim.api.nvim_create_user_command("NoLoad", function()
  vim.g.session_auto_load = false
end, {})

local load_au = vim.api.nvim_create_augroup("session_load", { clear = true })
local save_au = vim.api.nvim_create_augroup("session_save", { clear = true })

-- Load on enter

if vim.fn.argc() == 0 then
  vim.api.nvim_create_autocmd("VimEnter", {
    nested = true,
    group = load_au,
    desc = "Load session on `vim` with no args",
    callback = function()
      if vim.g.session_auto_load and vim.bo.buftype == "" then
        vim.cmd("silent! Load")
      end
      -- NOTE: Ask to open Git conflict files
      local when_conflict = function(files)
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
      end
      vim.system({ "git", "diff", "--relative", "--name-only", "--diff-filter=U" }, {}, function(out)
        if out.code == 0 then
          vim.schedule(function()
            when_conflict(vim.split(out.stdout or "", "\n", { trimempty = true }))
          end)
        end
      end)
    end,
  })
end

-- Save on leave

local should_close = function(win)
  win = win or 0
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.list_contains(vim.g.session_close_ft, vim.bo[buf].filetype)
end

vim.api.nvim_create_autocmd("VimLeave", {
  group = save_au,
  desc = "Save session on VimLeave",
  callback = function()
    if not vim.g.session_auto_save then
      return
    end
    local win_list = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local non_float = vim.api.nvim_win_get_config(win).relative == ""
      if
        non_float --
        and not (should_close(win) and pcall(vim.api.nvim_win_close, win, true))
      then
        table.insert(win_list, win)
      end
    end
    if #win_list == 1 then
      if should_close() or vim.bo.buftype ~= "" or vim.api.nvim_buf_get_name(0) == "" then
        return
      end
    end
    vim.cmd("silent! Save")
  end,
})
