local MiniFiles = require("mini.files")

local au = vim.api.nvim_create_augroup("minifiles_status", { clear = true })
local ns_git = vim.api.nvim_create_namespace("minifiles_git")
local ns_sym = vim.api.nvim_create_namespace("minifiles_sym")

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
local set_extmark = function(buf, ns, start_row, start_col, opts)
  opts = vim.tbl_extend("keep", opts, {
    invalidate = true, -- NOTE: hide if its range is deleted
    end_row = start_row,
    end_col = start_col,
    strict = false,
    hl_mode = "combine",
  })
  vim.api.nvim_buf_set_extmark(buf, ns, start_row, start_col, opts)
end

-- ◈ Symlinks

local render_sym = function(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns_sym, 0, -1)
  local fs_items = get_fs_items(buf)
  for _, item in ipairs(fs_items) do
    local lnum, fs_entry = item.lnum, item.fs_entry
    local fs_link = vim.uv.fs_readlink(fs_entry.path)
    if fs_link then
      local fs_stat = vim.uv.fs_stat(fs_entry.path)
      set_extmark(buf, ns_sym, lnum - 1, -1, {
        end_row = lnum, -- NOTE: Set to the next line to preserve it during inline edits
        end_col = 0,
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

-- ◈ Git status

local get_branch_dir = function(buf)
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local branch_dir = string.match(buf_name, "^minifiles://%d+/(.*)")
  if not branch_dir then
    return
  end
  return vim.fs.normalize(branch_dir)
end

local find_branch_root = function(branch_buf)
  local branch_dir = get_branch_dir(branch_buf)
  if not branch_dir then
    return
  end
  local git_root = vim.fs.root(branch_dir, ".git")
  if not git_root then
    return
  end
  return vim.fs.normalize(git_root)
end

local get_status = function(path, status_map)
  local status = status_map[path] or status_map[path .. "/"]
  if status then
    return status
  end
  -- NOTE: Check if inside an untracked folder
  for dir in vim.fs.parents(path) do
    status = status_map[dir .. "/"]
    if status then
      return status, dir
    end
  end
  return nil
end

local get_descendant_statuses = function(path, status_map)
  local child_statuses = {}
  for map_path, map_status in pairs(status_map) do
    local rel = vim.fs.relpath(path, map_path)
    if rel and rel ~= "." then
      child_statuses[map_path] = map_status
    end
  end
  return child_statuses
end

local get_deleted_items = function(buf, fs_items, status_map)
  local fs_entries = vim.tbl_map(function(item)
    return item.fs_entry
  end, fs_items)
  local is_deleted = function(status)
    return string.match(status, "D")
  end
  local branch_dir = assert(get_branch_dir(buf))
  local is_child = function(path)
    return vim.fs.dirname(path) == branch_dir
  end
  for map_path, map_status in pairs(status_map) do
    if is_deleted(map_status) and is_child(map_path) then
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

-- ◈◇ Renderer

local get_status_hl = function(xy)
  local x, y = string.sub(xy, 1, 1), string.sub(xy, 2, 2)
  if xy == "??" or xy == "!!" then -- Untracked, ignored
    return "NonText"
  elseif string.match(xy, "U") or xy == "AA" or xy == "DD" then -- Unmerged (conflict)
    return "DiagnosticError"
  elseif y == "D" then -- Unstaged: deleted
    return "DiagnosticError"
  elseif string.match(y, "[MTRC]") then -- Unstaged: modified/type-changed/renamed/copied
    return "DiagnosticWarn"
  elseif string.match(x, "[RC]") then -- Staged: renamed/copied
    return "DiagnosticHint"
  elseif string.match(x, "[AMTD]") then -- Staged: added/modified/type-changed/deleted
    return "DiagnosticOk"
  end
  return "Normal"
end

local get_entry_style = function(fs_entry, status_map)
  local path, fs_type = fs_entry.path, fs_entry.fs_type
  local own_status, _ = get_status(path, status_map)
  if own_status then
    return nil, get_status_hl(own_status)
  end
  if fs_type == "directory" then
    local child_statuses = get_descendant_statuses(path, status_map)
    if vim.tbl_isempty(child_statuses) then
      return nil, nil
    end
    local statuses = vim.tbl_values(child_statuses)
    -- NOTE: Group by color
    local first_hl = get_status_hl(statuses[1])
    local all_same = vim.iter(statuses):all(function(s)
      return get_status_hl(s) == first_hl
    end)
    local merge_hl = all_same and first_hl or get_status_hl(" M")
    local count = #statuses
    return (count > 99 and "99+" or count), merge_hl
  end
  return nil, nil
end

---@param buf integer
---@param status_map table<string, string>
local render_git = function(buf, status_map)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns_git, 0, -1)
  local fs_items = get_fs_items(buf)
  -- NOTE: 1. Display deleted entries as virtual lines
  local git_deleted = get_deleted_items(buf, fs_items, status_map)
  local prefix = MiniFiles.config.content.prefix
  for _, del_item in ipairs(git_deleted) do
    local lnum, status, fs_entry = del_item.lnum, del_item.status, del_item.fs_entry
    local status_hl = get_status_hl(status)
    local name_hl = fs_entry.fs_type == "file" and { status_hl, "@markup.strikethrough" } or status_hl
    set_extmark(buf, ns_git, lnum - 1, 0, {
      invalidate = false,
      virt_lines_above = true,
      virt_lines_overflow = "scroll",
      virt_lines = {
        { { prefix(fs_entry) }, { fs_entry.name, name_hl } },
      },
    })
  end
  -- HACK: Used to adjust the window height. See `MiniFilesWindowUpdate` below
  vim.b[buf].git_deleted = git_deleted
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_height(win, line_count + #git_deleted)
  end
  -- NOTE: 2. Display git status for visible entries
  for _, item in ipairs(fs_items) do
    local icon, hl_group = get_entry_style(item.fs_entry, status_map)
    local lnum, line = item.lnum, item.line
    if icon then
      local icon_text = string.gsub(icon, " ", "·")
      set_extmark(buf, ns_git, lnum - 1, 0, {
        virt_text = { { icon_text, hl_group } },
        virt_text_pos = "eol_right_align",
      })
    end
    if hl_group then
      -- NOTE: Start highlighting after the icon.
      --       Include `/` to keep the extmark when the first character is deleted
      local name_pos = string.match(line, "/.-/.-()/") -- /01/󰈔 /<name>
      if name_pos then
        set_extmark(buf, ns_git, lnum - 1, name_pos - 1, {
          end_row = lnum,
          end_col = 0,
          hl_group = hl_group,
        })
      end
    end
  end
end

-- ◈◇ GitStatus

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
        vim.notify("Git status failed: " .. (out.stderr or ""), vim.log.levels.WARN)
      end
      for _, cb in ipairs(subs) do
        cb(state, out)
      end
    end)
  end)
  return sys
end

-- NOTE: Call `GitStatus.query` separately to refresh the data
GitStatus.get_cached = function(git_root)
  git_root = vim.fs.normalize(git_root)
  local state = vim.deepcopy(GitStatus.store[git_root])
  if not state then
    return nil, false
  end
  local is_fresh = os.time() < state.expires_at
  return state, is_fresh
end

GitStatus.expire = function()
  for _, state in pairs(GitStatus.store) do
    state.expires_at = -1
  end
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

-- ◈◇ MiniFilesStatus

_G.MiniFilesStatus = {} -- NOTE: Public API

MiniFilesStatus.get_status = function(path)
  path = vim.fs.normalize(path)
  local status, source, children
  local outer_root = vim.iter(vim.fs.parents(path)):find(function(dir)
    return GitStatus.store[dir] ~= nil
  end)
  local outer_state = outer_root and GitStatus.get_cached(outer_root)
  if outer_state then
    status, source = get_status(path, outer_state.map)
  end
  local inner_state = GitStatus.store[path] and GitStatus.get_cached(path) or outer_state
  children = inner_state and get_descendant_statuses(path, inner_state.map) or {}
  if not status and vim.tbl_isempty(children) then
    return nil
  end
  return {
    status = status,
    source = source,
    children = children,
  }
end

local get_rooted_branches = function(filter_root)
  local rooted_branches = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local buf_root = find_branch_root(buf)
    if buf_root and (filter_root == nil or filter_root == buf_root) then
      rooted_branches[buf] = buf_root
    end
  end
  return rooted_branches
end

MiniFilesStatus.synchronize = function(git_root) ---@param git_root? string
  for buf, buf_root in pairs(get_rooted_branches(git_root)) do
    GitStatus.query(buf_root, function(state)
      render_git(buf, state.map)
    end)
  end
end

-- ◈◇ Setup

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
    vim.api.nvim_win_set_height(win, lnum_count + #git_deleted)
  end,
})

local update_status = function(buf, force)
  local git_root = find_branch_root(buf)
  if not git_root then
    return
  end
  local is_new = vim.b[buf].git_root == nil
  vim.b[buf].git_root = git_root
  -- NOTE: Stale-while-revalidate: render now, refresh later
  local cached, is_fresh = GitStatus.get_cached(git_root)
  if cached then
    render_git(buf, cached.map)
  end
  -- NOTE: Avoid a redundant query after `go_in`
  if not force and is_new and is_fresh then
    return
  end
  GitStatus.query(git_root, function(state)
    render_git(buf, state.map)
  end)
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferUpdate",
  group = au,
  desc = "Update/render `mini.files` git status",
  callback = function(e)
    update_status(e.data.buf_id)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniGitUpdated",
  group = au,
  desc = "Synchronize `mini.files` git status after `mini.git` updates",
  callback = function(e)
    local MiniGit = require("mini.git")
    local git_root = (MiniGit.get_buf_data(e.buf) or {}).root
    if git_root then
      MiniFilesStatus.synchronize(git_root)
    end
  end,
})

vim.api.nvim_create_autocmd("FocusGained", {
  group = au,
  desc = "Synchronize `mini.files` git status after gaining focus",
  callback = function()
    MiniFilesStatus.synchronize()
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesExplorerClose",
  group = au,
  desc = "Clean up `mini.files` git status",
  callback = function()
    GitStatus.prune()
    -- NOTE: Force statuses to refresh when reopening
    GitStatus.expire()
  end,
})
