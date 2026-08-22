local M = {}

_G.MiniFiles = _G.MiniFiles
_G.MiniPick = _G.MiniPick
_G.MiniFilesStatus = _G.MiniFilesStatus

M.get_branch = function(buf)
  buf = buf or 0
  local buf_name = vim.api.nvim_buf_get_name(buf)
  return string.match(buf_name, "^minifiles://%d+/(.*)")
end

M.set_cursor_path = function(win, path)
  win = win or 0
  local buf = vim.api.nvim_win_get_buf(win)
  for i = 1, vim.api.nvim_buf_line_count(buf) do
    if MiniFiles.get_fs_entry(buf, i).path == path then
      vim.api.nvim_win_set_cursor(win, { i, 0 })
      break
    end
  end
end

-- See https://github.com/nvim-mini/mini.nvim/issues/928#issuecomment-3399048448
M.set_bookmark = function(id, local_path, opts)
  MiniFiles.set_bookmark(id, function()
    local path = type(local_path) == "function" and local_path() or local_path
    if type(path) ~= "string" then
      return
    end
    path = vim.fs.abspath(path)
    local stat = vim.uv.fs_stat(path)
    if not stat then
      return
    end
    vim.schedule(function()
      M.set_cursor_path(0, path)
    end)
    return vim.fs.dirname(path)
  end, opts)
end

---@class MiniFilesEntry
---@field fs_type "file"|"directory"
---@field name string
---@field path string
---@field lnum integer
---@field line string

---@return MiniFilesEntry[], MiniFilesEntry?
M.get_selected = function()
  local mode = vim.api.nvim_get_mode().mode
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local min_row, max_row = row, row
  if string.match(mode, "[vV\22]") then
    local visual_row = vim.fn.line("v")
    min_row, max_row = math.min(row, visual_row), math.max(row, visual_row)
  end
  local selected, current = {}, nil
  for lnum = min_row, max_row do
    local fs_entry = MiniFiles.get_fs_entry(0, lnum)
    if fs_entry then
      local item = vim.tbl_extend("keep", fs_entry, {
        lnum = lnum,
        line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1],
      })
      table.insert(selected, item)
      if lnum == row then
        current = item
      end
    end
  end
  return selected, current
end

M.get_preview_win = function()
  if not MiniFiles.config.windows.preview then
    return
  end
  local ok, state = pcall(MiniFiles.get_explorer_state)
  if not ok or not state then
    return
  end
  local rmost_win = state.windows[#state.windows].win_id
  if rmost_win == vim.api.nvim_get_current_win() then
    return
  end
  return state.windows[#state.windows].win_id
end

-- Actions

M.actions = {}

M.actions.mark_set = function()
  local id = vim.fn.getcharstr()
  if not id or id == "" or id == "\27" then
    return
  end
  local _, current = M.get_selected()
  if not current then
    return
  end
  M.set_bookmark(id, current.path)
  vim.notify("Bookmark " .. vim.inspect(id) .. " is set")
end

M.actions.set_cwd = function()
  local _, current = M.get_selected()
  if not current then
    return
  end
  local dirname = vim.fs.dirname(current.path)
  vim.fn.chdir(dirname)
  vim.notify("Set cwd: " .. dirname)
end

M.actions.ui_open = function()
  local _, current = M.get_selected()
  if not current then
    return
  end
  vim.ui.open(current.path)
end

M.actions.yank_path = function()
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
  local register = vim.v.register
  local selected, _ = M.get_selected()
  local notify = vim.schedule_wrap(vim.notify)
  if vim.tbl_isempty(selected) then
    notify("No paths to yank", vim.log.levels.WARN)
  else
    local copy_str = vim.iter(selected):fold("", function(acc, fs_entry)
      return acc .. "\n" .. fs_entry.path
    end)
    vim.fn.setreg(register, copy_str)
    notify(string.format("Yanked %d %s", #selected, #selected == 1 and "path" or "paths"))
  end
end

M.actions.split = function(dir)
  local _, current = M.get_selected()
  if not current or current.fs_type == "directory" then
    return
  end
  local target_win = MiniFiles.get_explorer_state().target_window
  target_win = vim.api.nvim_win_call(target_win, function()
    vim.cmd(dir .. " split")
    return vim.api.nvim_get_current_win()
  end)
  MiniFiles.set_target_window(target_win)
  MiniFiles.go_in()
end

local show_hidden = true
M.actions.toggle_hidden = function()
  show_hidden = not show_hidden
  local filter_show = function()
    return true
  end
  local filter_hide = function(fs_entry)
    return not vim.startswith(fs_entry.name, ".")
  end
  MiniFiles.refresh({
    content = { filter = show_hidden and filter_show or filter_hide },
  })
end

-- See https://github.com/nvim-mini/mini.nvim/discussions/936#discussioncomment-14667620
M.actions.toggle_preview = function()
  local is_enabled = MiniFiles.config.windows.preview
  local enable = not is_enabled
  MiniFiles.config.windows.preview = enable
  MiniFiles.trim_right()
  MiniFiles.refresh({ windows = { preview = enable } })
  MiniFiles.refresh()
  if is_enabled then
    local branch = MiniFiles.get_explorer_state().branch
    table.remove(branch)
    MiniFiles.set_branch(branch)
  end
end

local preview_win_call = function(callback)
  local win = M.get_preview_win()
  if win then
    vim.api.nvim_win_call(win, callback)
  end
end

M.actions.norm_in_preview = function(keys)
  preview_win_call(function()
    local key = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.cmd.norm({ key, bang = true })
  end)
end

M.actions.jump_edges = function()
  preview_win_call(function()
    local last = vim.fn.line(".") == vim.fn.line("$")
    vim.cmd.norm({ last and "gg" or "G", bang = true })
  end)
end

-- -- Alt

local alt_entry = nil

local new_alt = function()
  local state = MiniFiles.get_explorer_state()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line_count = vim.api.nvim_buf_line_count(0)
  local path
  for i = 0, line_count - 1 do
    local ln = (row + i - 1) % line_count + 1
    local ok, fs_entry = pcall(MiniFiles.get_fs_entry, 0, ln)
    if ok and fs_entry then
      path = fs_entry.path
      break
    end
  end
  return {
    branch = state.branch,
    depth_focus = state.depth_focus,
    cursor_path = path,
  }
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesExplorerClose",
  desc = "Save `mini.files` alternate entry on close",
  group = vim.api.nvim_create_augroup("config/minifiles.alt", { clear = true }),
  callback = function()
    alt_entry = new_alt()
  end,
})

M.actions.edit_alt = function()
  if alt_entry then
    local curr_alt_entry = new_alt()
    MiniFiles.set_branch(alt_entry.branch, { depth_focus = alt_entry.depth_focus })
    if alt_entry.cursor_path then
      pcall(M.set_cursor_path, alt_entry.cursor_path)
    end
    alt_entry = curr_alt_entry
  end
end

-- -- Search

M.actions.minipick = {}

M.actions.minipick.search_grep = function()
  local _, current = M.get_selected()
  if not current then
    return
  end
  local parent = vim.fn.fnamemodify(current.path, ":h")
  MiniFiles.close()
  MiniPick.registry.grep({ pattern = "." }, { source = { cwd = parent } })
end

M.actions.minipick.search_files = function()
  local _, current = M.get_selected()
  if not current then
    return
  end
  local parent = vim.fn.fnamemodify(current.path, ":h")
  MiniFiles.close()
  MiniPick.registry.files(nil, { source = { cwd = parent } })
end

-- -- Git

local get_selected_paths = function()
  local selected, current = M.get_selected()
  local selected_paths = vim.tbl_map(function(sel)
    return sel.path
  end, selected)
  return selected_paths, selected, current
end

local try_synchronize = function()
  local confirm = vim.fn.confirm
  vim.fn.confirm = function() ---@diagnostic disable-line: duplicate-set-field
    return 3
  end
  local ok = MiniFiles.synchronize()
  vim.fn.confirm = confirm
  return ok
end

---@param opts { branch_buf: integer, cmd: string[], sync?: boolean }
local git_run = function(opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    branch_buf = 0,
    cmd = {},
    sync = true,
  })
  if opts.sync and not try_synchronize() then
    vim.notify("(mini.files) Git command skipped. Synchronize first", vim.log.levels.WARN)
    return
  end
  vim.system(opts.cmd, { cwd = M.get_branch(opts.branch_buf) }, function(out)
    vim.schedule(function()
      local mode = vim.api.nvim_get_mode().mode
      if string.match(mode, "[vV\22]") then
        vim.api.nvim_input("<Esc>")
      end
      if out.code ~= 0 then
        return
      end
      if opts.sync and try_synchronize() then
        return
      end
      MiniFilesStatus.refresh()
    end)
  end)
end

local get_entry_status = function(buf, lnum)
  assert(MiniFilesStatus and MiniFilesStatus.status_of, "`MiniFilesStatus.status_of` is not available")
  local fs_entry = MiniFiles.get_fs_entry(buf, lnum)
  if not fs_entry then
    return nil
  end
  return MiniFilesStatus.status_of(fs_entry.path), fs_entry
end

local get_status_codes = function(status)
  if not status then
    return {}
  end
  local status_codes = {}
  vim.list_extend(status_codes, { status.status })
  vim.list_extend(status_codes, vim.tbl_values(status.children or {}))
  return status_codes
end

M.actions.git_toggle_stage = function()
  local selected_paths, selected = get_selected_paths()
  local all_staged = vim.iter(selected):all(function(sel)
    local status = get_entry_status(0, sel.lnum)
    if not status then
      return true
    end
    local status_codes = get_status_codes(status)
    return vim.iter(status_codes):all(function(xy)
      return xy and string.sub(xy, 1, 1) ~= " " and xy ~= "??"
    end)
  end)
  if all_staged then
    git_run({ cmd = { "git", "restore", "--staged", unpack(selected_paths) } })
  else
    git_run({ cmd = { "git", "add", unpack(selected_paths) } })
  end
end

M.actions.git_restore = function()
  local selected_paths = get_selected_paths()
  git_run({ cmd = { "git", "restore", unpack(selected_paths) } })
end

M.actions.git_goto = function(dir)
  local lnum_count = vim.api.nvim_buf_line_count(0)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local where = {
    next = { row + 1, lnum_count, 1 },
    prev = { row - 1, 1, -1 },
    first = { 1, lnum_count, 1 },
    last = { lnum_count, 1, -1 },
  }
  local conf = assert(where[dir], "Unknown `dir`: " .. tostring(dir))
  for i = conf[1], conf[2], conf[3] do
    local fs_entry = MiniFiles.get_fs_entry(0, i)
    if fs_entry then
      local status = get_entry_status(0, i)
      if status then
        vim.api.nvim_win_set_cursor(0, { i, col })
        return
      end
    end
  end
end

return M
