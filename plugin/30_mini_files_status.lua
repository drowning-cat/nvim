local MiniFiles = require("mini.files")

local au = vim.api.nvim_create_augroup("minifiles_status", { clear = true })
local ns_git = vim.api.nvim_create_namespace("minifiles_git")
local ns_sym = vim.api.nvim_create_namespace("minifiles_sym")

-- Share

local iter_fs = function(buf)
  local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local lnum = 0
  return function()
    while lnum < #buf_lines do
      lnum = lnum + 1
      local fs_entry = MiniFiles.get_fs_entry(buf, lnum)
      if fs_entry then
        return lnum, buf_lines[lnum], fs_entry
      end
    end
  end
end

local set_extmark = function(buf, ns, row, start_col, end_col, opts)
  start_col, end_col = start_col or 0, end_col or -1
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
  for lnum, _, fs_entry in iter_fs(buf) do
    local fs_link = vim.uv.fs_readlink(fs_entry.path)
    if fs_link then
      local virt_text = string.format(" → %s", vim.fn.pathshorten(fs_link))
      set_extmark(buf, ns_sym, lnum - 1, -1, -1, {
        virt_text = { { virt_text, "NonText" } },
        virt_text_pos = "overlay",
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

local root_cache = {}

local get_branch_dir = function(buf)
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local dir = string.match(buf_name, "^minifiles://%d+/(.*)")
  return assert(dir)
end

local find_root = function(branch_buf, force)
  local dir = get_branch_dir(branch_buf)
  if force == true or root_cache[dir] == nil then
    local root = vim.fs.root(dir, ".git")
    -- NOTE: Use `false` to distinguish "not found" from "never checked" (nil)
    root_cache[dir] = root or false
  end
  return root_cache[dir] or nil
end

-- Fetch

---@type table<string, { sys: vim.SystemObj, subs: fun(status_map: table<string, string>)[] }>
local fetch_state = {}

local parse_status = function(stdout, join_path)
  local status_map = {}
  local chunk_list = vim.split(stdout, "%z")
  local i = 1
  while i <= #chunk_list do
    local chunk = chunk_list[i]
    local status, rel_path = string.match(chunk, "^(..) (.*)")
    if status and rel_path then
      local abs_path = vim.fs.joinpath(join_path, rel_path)
      status_map[abs_path] = status
      -- NOTE: Rename/copy entries are followed by an additional old path
      if string.match(status, "^[RC]") then
        i = i + 1
      end
    end
    i = i + 1
  end
  return status_map
end

local fetch_git_status = function(git_root, on_done)
  local root = vim.fs.normalize(git_root)
  if fetch_state[root] then
    -- NOTE: Collapse identical requests into a single `vim.system` call
    table.insert(fetch_state[root].subs, on_done)
    return
  end
  fetch_state[root] = { subs = { on_done } }
  local sys = vim.system({ "git", "status", "--ignored", "--porcelain", "--null" }, { cwd = root }, function(out)
    vim.schedule(function()
      local status_map = {}
      if out.code == 0 and out.stdout then
        status_map = parse_status(out.stdout, git_root)
      end
      local subs = fetch_state[root].subs
      for _, cb in ipairs(subs) do
        cb(status_map)
      end
      fetch_state[root] = nil
    end)
  end)
  fetch_state[root].sys = sys
  return sys
end

local abort_fetches = function()
  for git_root, stat in pairs(fetch_state) do
    local sys = stat.sys
    if sys and not sys:is_closing() then
      sys:kill("sigterm")
    end
    fetch_state[git_root] = nil
  end
end

-- Render

local render_git = function(buf, status_map)
  vim.api.nvim_buf_clear_namespace(buf, ns_git, 0, -1)
  for lnum, line, fs_entry in iter_fs(buf) do
    local status = status_map[fs_entry.path]
    if status then
      local x, y = status:sub(1, 1), status:sub(2, 2)
      local hl_group = "Normal"
      if x == "U" or y == "U" then
        hl_group = "MiniDiffSignDelete"
      elseif status == "??" or status == "!!" then
        hl_group = "NonText"
      elseif x ~= " " then
        hl_group = "DiagnosticHint"
      elseif y ~= " " then
        hl_group = "DiagnosticWarn"
      end
      set_extmark(buf, ns_git, lnum - 1, 0, 0, {
        virt_text = { { string.gsub(status, " ", "·"), hl_group } },
        virt_text_pos = "eol_right_align",
      })
      local text_start = string.match(line, "/.-/.-/()") -- After the icon
      if text_start and hl_group then
        set_extmark(buf, ns_git, lnum - 1, text_start - 1, -1, { hl_group = hl_group })
      end
    end
  end
end

-- Setup

-- NOTE: `status_store` is kept across explorer openings
local status_store = {}

local on_status = function(buf, status_map)
  if vim.api.nvim_buf_is_valid(buf) then
    render_git(buf, status_map)
  end
end

local refresh_status = function(git_root, on_done)
  fetch_git_status(git_root, function(status_map)
    status_store[git_root] = status_map
    on_done(status_map)
  end)
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferUpdate",
  group = au,
  desc = "Update `mini.files` git status",
  callback = function(e)
    local buf = e.data.buf_id
    local git_root = find_root(buf, false)
    if not git_root then
      return
    end
    local cached = status_store[git_root]
    -- NOTE: Prefer cached, but re-fetch when a new `git_root` is found
    if cached then
      on_status(buf, cached)
    else
      refresh_status(git_root, function(status_map)
        on_status(buf, status_map)
      end)
    end
  end,
})

local sync = MiniFiles.synchronize
MiniFiles.synchronize = function(...)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local ret = sync(...)
  pcall(vim.api.nvim_win_set_cursor, 0, cursor)
  vim.api.nvim_exec_autocmds("User", { pattern = { "_MiniFilesExplorerSync" } })
  return ret
end

-- NOTE: Re-fetch git statuses on open and during synchronization (triggered by `=` key)
vim.api.nvim_create_autocmd("User", {
  pattern = { "MiniFilesExplorerOpen", "_MiniFilesExplorerSync" },
  group = au,
  desc = "Re-fetch `mini.files` git statuses",
  callback = function()
    for git_root in pairs(status_store) do
      -- NOTE: Lazily re-fetch git data and refresh affected buffers
      refresh_status(git_root, function(status_map)
        local state = MiniFiles.get_explorer_state()
        if state then
          for _, win_item in ipairs(state.windows) do
            local buf = vim.api.nvim_win_get_buf(win_item.win_id)
            local dir = get_branch_dir(buf)
            if vim.fs.relpath(git_root, dir) and (find_root(buf, true) == git_root) then
              on_status(buf, status_map)
            end
          end
        end
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesExplorerClose",
  group = au,
  desc = "Abort `mini.files` git fetches",
  callback = function()
    abort_fetches()
  end,
})
