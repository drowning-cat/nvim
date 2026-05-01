local MiniFiles = require("mini.files")

local au = vim.api.nvim_create_augroup("minifiles_status", { clear = true })
local ns_git = vim.api.nvim_create_namespace("minifiles_git")
local ns_sym = vim.api.nvim_create_namespace("minifiles_sym")

-- Share

local get_fs_items = function(buf)
  local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local fs_items = {}
  for lnum, line in ipairs(buf_lines) do
    local fs_entry = MiniFiles.get_fs_entry(buf, lnum)
    if fs_entry then
      table.insert(fs_items, { lnum = lnum, line = line, fs_entry = fs_entry })
    end
  end
  return fs_items
end

---@param opts vim.api.keyset.set_extmark
local set_extmark = function(buf, ns, row, start_col, end_col, opts)
  opts = vim.tbl_extend("keep", opts, {
    invalidate = true,
    end_row = row,
    end_col = end_col,
    strict = false,
    hl_mode = "combine",
  })
  vim.api.nvim_buf_set_extmark(buf, ns, row, start_col, opts)
end

-- Symlinks

local render_sym = function(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns_sym, 0, -1)
  local fs_items = get_fs_items(buf)
  for _, item in ipairs(fs_items) do
    local lnum, fs_entry = item.lnum, item.fs_entry
    local fs_link = vim.uv.fs_readlink(fs_entry.path)
    if fs_link then
      local fs_stat = vim.uv.fs_stat(fs_entry.path)
      set_extmark(buf, ns_sym, lnum - 1, -1, -1, {
        virt_text_pos = "overlay",
        virt_text = {
          { " → ", "NonText" },
          { vim.fn.pathshorten(fs_link), fs_stat and "NonText" or "ErrorMsg" },
        },
      })
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferUpdate",
  group = au,
  desc = "Update `mini.files` symlinks",
  callback = function(e)
    render_sym(e.data.buf_id)
  end,
})

-- Git status

local buf_get_branch = function(buf)
  local buf_name = vim.api.nvim_buf_get_name(buf)
  return string.match(buf_name, "^minifiles://%d+/(.*)")
end

local find_root = function(branch_buf)
  local branch_dir = buf_get_branch(branch_buf)
  if not branch_dir then
    return
  end
  local git_root = vim.fs.root(branch_dir, ".git")
  if not git_root then
    return
  end
  return vim.fs.normalize(git_root)
end

local Hl = {
  UNTRACKED = "NonText",
  CONFLICT = "DiagnosticError",
  ADDED = "DiagnosticOk",
  RENAMED = "DiagnosticHint",
  MODIFIED = "DiagnosticWarn",
  DEFAULT = "Normal",
  -- Custom (strikethrough)
  DELETED = "MiniFilesDeleted",
  DELETED_STAGED = "MiniFilesDeletedStaged",
}

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = au,
  desc = "Define custom `mini.files` status highlights",
  callback = function()
    local set_strikethrough = function(name, base_name)
      local hl = vim.api.nvim_get_hl(0, { name = base_name, link = false })
      local new_hl = { fg = hl.fg, bg = hl.bg, strikethrough = true }
      vim.api.nvim_set_hl(0, name, new_hl)
    end
    set_strikethrough("MiniFilesDeleted", Hl.CONFLICT)
    set_strikethrough("MiniFilesDeletedStaged", Hl.ADDED)
  end,
})

---@param status string
---@param fs_type "directory"|"file"
local get_status_hl = function(status, fs_type)
  if status == "??" or status == "!!" then
    return Hl.UNTRACKED
  elseif string.match(status, "U") or status == "AA" or status == "DD" then
    return Hl.CONFLICT
  elseif string.sub(status, 2, 2) == "D" then
    return fs_type == "directory" and Hl.CONFLICT or Hl.DELETED
  elseif string.sub(status, 1, 1) == "D" then
    return fs_type == "directory" and Hl.ADDED or Hl.DELETED_STAGED
  elseif string.match(status, "[AC]") then
    return Hl.ADDED
  elseif string.match(status, "R") then
    return Hl.RENAMED
  elseif string.match(status, "M") then
    return Hl.MODIFIED
  end
  return Hl.DEFAULT
end

local get_deleted_items = function(buf, fs_items, status_map)
  local branch_dir = assert(buf_get_branch(buf))
  local fs_entries = vim.tbl_map(function(item)
    return item.fs_entry
  end, fs_items)
  local is_deleted = function(status)
    return string.match(status, "D")
  end
  for map_path, map_status in pairs(status_map) do
    if is_deleted(map_status) and vim.fs.dirname(map_path) == branch_dir then
      table.insert(fs_entries, {
        fs_type = "file",
        name = vim.fs.basename(map_path),
        path = map_path,
      })
    end
  end
  fs_entries = MiniFiles.config.content.sort(fs_entries)
  local deleted_items = {}
  local filter = MiniFiles.config.content.filter
  for lnum, fs_entry in ipairs(fs_entries) do
    local status = status_map[fs_entry.path]
    if status and is_deleted(status) and filter(fs_entry) then
      table.insert(deleted_items, {
        lnum = lnum - #deleted_items,
        fs_entry = fs_entry,
        status = status,
      })
    end
  end
  return deleted_items
end

---@param status_map table<string, string>
local render_git = function(buf, status_map)
  vim.api.nvim_buf_clear_namespace(buf, ns_git, 0, -1)
  local fs_items = get_fs_items(buf)
  -- NOTE: 1. Display deleted entries as virtual lines
  local deleted_items = get_deleted_items(buf, fs_items, status_map)
  local prefix = MiniFiles.config.content.prefix
  for _, del_item in ipairs(deleted_items) do
    local lnum, fs_entry, status = del_item.lnum, del_item.fs_entry, del_item.status
    set_extmark(buf, ns_git, lnum - 1, 0, 0, {
      virt_lines_above = true,
      virt_lines_overflow = "scroll",
      virt_lines = {
        { { prefix(fs_entry) }, { fs_entry.name, get_status_hl(status, "file") } },
      },
    })
  end
  -- HACK: Used to adjust the window height. See `MiniFilesWindowUpdate` below
  vim.b[buf].git_deleted = deleted_items
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_height(win, line_count + #deleted_items)
  end
  -- NOTE: 2. Display git status for visible entries
  local get_entry_style = function(fs_entry)
    local fs_type, path = fs_entry.fs_type, fs_entry.path
    local status = status_map[path] or status_map[path .. "/"]
    if status then
      return nil, get_status_hl(status, fs_type)
    end
    -- NOTE: Check if inside an untracked folder
    for dir in vim.fs.parents(path) do
      status = status_map[dir .. "/"]
      if status then
        return nil, get_status_hl(status, fs_type)
      end
    end
    if fs_type == "directory" then
      local child_statuses = {}
      for map_path, map_status in pairs(status_map) do
        local rel = vim.fs.relpath(path, map_path)
        if rel and rel ~= "." then
          table.insert(child_statuses, map_status)
        end
      end
      local count = #child_statuses
      if count > 0 then
        status = count > 1 and " M" or child_statuses[1]
        local icon = count > 99 and "99+" or count
        return icon, get_status_hl(status, fs_type)
      end
    end
    return nil, nil
  end
  for _, item in ipairs(fs_items) do
    local lnum, line = item.lnum, item.line
    local icon, hl_group = get_entry_style(item.fs_entry)
    -- NOTE: Show the #icon on the right
    if icon then
      set_extmark(buf, ns_git, lnum - 1, 0, 0, {
        virt_text = { { string.gsub(icon, " ", "·"), hl_group } },
        virt_text_pos = "eol_right_align",
      })
    end
    if hl_group then
      -- NOTE: Start highlighting after the icon.
      --       Include `/` to preserve the highlight if the name changes at the start
      local name_pos = string.match(line, "/.-/.-()/") -- /01/󰈔 /<name>
      if name_pos then
        set_extmark(buf, ns_git, lnum - 1, name_pos - 1, -1, { hl_group = hl_group })
      end
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesWindowUpdate",
  group = au,
  desc = "Increase window height to fit deleted entries",
  callback = function(e)
    local win, buf = e.data.win_id, e.data.buf_id
    local git_deleted = vim.b[buf].git_deleted
    if not git_deleted then
      return
    end
    local lnum_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_height(win, lnum_count + vim.tbl_count(git_deleted))
  end,
})

local GitStatus = {}

---@class RootState
---@field map table<string, string>
---@field subs fun(state: self, out: vim.SystemCompleted)[]
---@field updated_at integer
---@field expires_at integer
---@field error? vim.SystemCompleted

---@type table<string, RootState>
GitStatus.store = {}

GitStatus.ttl = math.huge -- disabled; seconds
GitStatus.cleanup_keep = 3

GitStatus._parse_porcelain = function(git_root, stdout)
  local status_map = {}
  local chunk_list = vim.split(stdout, "%z")
  local i = 1
  while i <= #chunk_list do
    local chunk = chunk_list[i]
    -- NOTE: Path is relative to the git repository
    local status, rel_path = string.match(chunk, "^(..) (.*)")
    if status and rel_path then
      -- NOTE: Windows: "a\foo\", "\bar" => "a/foo/bar"
      local abs_path = vim.fs.joinpath(git_root, rel_path)
      status_map[abs_path] = status
      -- NOTE: Rename/copy entries are followed by an additional original path
      if string.match(status, "[RC]") then
        i = i + 1
      end
    end
    i = i + 1
  end
  return status_map
end

GitStatus.query = function(git_root, on_done)
  git_root = vim.fs.normalize(git_root)
  local state = GitStatus.store[git_root]
  if not state then
    state = { map = {}, subs = {}, updated_at = -1, expires_at = -1 }
    GitStatus.store[git_root] = state
  end
  local is_fetching = not vim.tbl_isempty(state.subs)
  if is_fetching then
    -- NOTE: Coalesce identical requests into a single `vim.system` call
    table.insert(state.subs, on_done)
    return
  end
  state.subs = { on_done }
  -- WARN: Untracked directories end with `/`; files inside are not reported
  local sys = vim.system({ "git", "status", "--ignored", "--porcelain", "--null" }, { cwd = git_root }, function(out)
    vim.schedule(function()
      local subs = state.subs
      state.subs = {}
      if out.code == 0 and out.stdout then
        local status_map = GitStatus._parse_porcelain(git_root, out.stdout)
        -- NOTE: Manually include the `.git` directory in case it's used
        status_map[vim.fs.joinpath(git_root, ".git/")] = "!!"
        state.map = status_map
        state.updated_at = os.time()
        state.expires_at = state.updated_at + GitStatus.ttl
        state.error = nil
      else
        state.error = out
        vim.notify("Git status failed: " .. out.stderr, vim.log.levels.WARN)
      end
      for _, cb in ipairs(subs) do
        cb(state, out)
      end
    end)
  end)
  return sys
end

GitStatus.expire = function()
  for _, state in pairs(GitStatus.store) do
    state.expires_at = -1
  end
end

GitStatus.get = function(git_root)
  git_root = vim.fs.normalize(git_root)
  local state = GitStatus.store[git_root]
  if not state then
    return nil, false
  end
  local is_fresh = os.time() < state.expires_at
  return state, is_fresh
end

GitStatus.prune = function(keep_count)
  keep_count = keep_count or GitStatus.cleanup_keep or 0
  local roots = vim.tbl_keys(GitStatus.store)
  if #roots <= keep_count then
    return
  end
  -- NOTE: Keep the latest N entries
  table.sort(roots, function(a, b)
    return GitStatus.store[a].updated_at > GitStatus.store[b].updated_at
  end)
  for i = keep_count + 1, #roots do
    GitStatus.store[roots[i]] = nil
  end
end

local synchronize = MiniFiles.synchronize
MiniFiles.synchronize = function(...)
  GitStatus.expire() -- NOTE: Force `is_fresh=false` before `MiniFilesBufferUpdate`
  return synchronize(...)
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferUpdate",
  group = au,
  desc = "Render `mini.files` git status",
  callback = function(e)
    local buf = e.data.buf_id
    local git_root = find_root(buf)
    if not git_root then
      return
    end
    local cached, is_fresh = GitStatus.get(git_root)
    if cached then
      render_git(buf, cached.map)
    end
    if not is_fresh then
      GitStatus.query(git_root, function(state)
        render_git(buf, state.map)
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesExplorerClose",
  group = au,
  desc = "Clean up `mini.files` git status",
  callback = function()
    GitStatus.prune()
    GitStatus.expire()
  end,
})
