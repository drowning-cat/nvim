local pack = require("util.pack")

_G.MiniClue = _G.MiniClue
_G.MiniPick = _G.MiniPick

pack.plug(function()
  local MiniFiles = require("mini.files")

  local au = vim.api.nvim_create_augroup("minifiles", { clear = true })

  MiniFiles.setup({
    options = {
      permanent_delete = false,
    },
    windows = {
      preview = false,
      width_preview = 100,
    },
    mappings = {
      -- NOTE: See buffer keymaps
      mark_set = "M",
    },
  })

  -- stylua: ignore start
  vim.keymap.set("n", "<Leader>F", function() MiniFiles.open() end, { desc = "Open files" })
  vim.keymap.set("n", "<Leader>.F", function() MiniFiles.open(vim.fn.expand("%:p")) end, { desc = "Open files (buf)" })
  vim.keymap.set("n", "<Leader>@F", function() MiniFiles.open(vim.fn.getcwd()) end, { desc = "Open files (cwd)" })
  vim.keymap.set("n", "<Leader>~F", function() MiniFiles.open("~") end, { desc = "Open files (system home)" })
  -- stylua: ignore end

  local buf_get_path = function(buf)
    local path = vim.api.nvim_buf_get_name(buf):match("^minifiles://%d+/(.*)$")
    local stat = vim.uv.fs_stat(path)
    return path, stat
  end

  local set_cursor_path = function(win, path)
    win = win or 0
    local buf = vim.api.nvim_win_get_buf(win)
    for i = 1, vim.api.nvim_buf_line_count(buf) do
      if MiniFiles.get_fs_entry(buf, i).path == path then
        vim.api.nvim_win_set_cursor(win, { i, 0 })
        break
      end
    end
  end

  local get_preview_win = function()
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

  local preview_win_call = function(callback)
    local win = get_preview_win()
    if win then
      vim.api.nvim_win_call(win, callback)
    end
  end

  ---@class MiniFilesEntry
  ---@field fs_type "file"|"directory"
  ---@field name string
  ---@field path string
  ---@field lnum integer
  ---@field line string

  ---@return MiniFilesEntry[], MiniFilesEntry?
  local get_selected = function()
    local mode = vim.api.nvim_get_mode().mode
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local min_row, max_row = row, row
    if mode:match("[vV\22]") then
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

  -- Keymaps

  local Action = {}

  local set_bookmark = function(id, local_path, opts)
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
        set_cursor_path(0, path)
      end)
      return vim.fs.dirname(path)
    end, opts)
  end

  Action.mark_set = function()
    local id = vim.fn.getcharstr()
    if not id or id == "" or id == "\27" then
      return
    end
    local _, current = get_selected()
    if not current then
      return
    end
    set_bookmark(id, current.path)
    vim.notify("Bookmark " .. vim.inspect(id) .. " is set")
  end

  Action.set_cwd = function()
    local _, current = get_selected()
    if not current then
      return
    end
    local dirname = vim.fs.dirname(current.path)
    vim.fn.chdir(dirname)
    vim.notify("Set cwd: " .. dirname)
  end

  Action.ui_open = function()
    local _, current = get_selected()
    if not current then
      return
    end
    vim.ui.open(current.path)
  end

  Action.yank_path = function()
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
    local register = vim.v.register
    local selected, _ = get_selected()
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

  Action.split = function(dir)
    local _, current = get_selected()
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
  Action.toggle_hidden = function()
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

  Action.toggle_preview = function()
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

  Action.norm_in_preview = function(keys)
    preview_win_call(function()
      local key = vim.api.nvim_replace_termcodes(keys, true, false, true)
      vim.cmd.norm({ key, bang = true })
    end)
  end

  Action.jump_edges = function()
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
    group = au,
    callback = function()
      alt_entry = new_alt()
    end,
  })

  Action.edit_alt = function()
    if alt_entry then
      local curr_alt_entry = new_alt()
      MiniFiles.set_branch(alt_entry.branch, { depth_focus = alt_entry.depth_focus })
      if alt_entry.cursor_path then
        pcall(set_cursor_path, alt_entry.cursor_path)
      end
      alt_entry = curr_alt_entry
    end
  end

  -- -- Search

  Action.minipick = {}

  Action.minipick.search_grep = function()
    local _, current = get_selected()
    if not current then
      return
    end
    local parent = vim.fn.fnamemodify(current.path, ":h")
    MiniFiles.close()
    MiniPick.registry.grep({ pattern = "." }, { source = { cwd = parent } })
  end

  Action.minipick.search_files = function()
    local _, current = get_selected()
    if not current then
      return
    end
    local parent = vim.fn.fnamemodify(current.path, ":h")
    MiniFiles.close()
    MiniPick.registry.files(nil, { source = { cwd = parent } })
  end

  -- -- Git

  local get_selected_paths = function()
    local selected, _ = get_selected()
    local selected_paths = vim.tbl_map(function(sel)
      return sel.path
    end, selected)
    return selected_paths, selected
  end

  local get_branch = function(buf)
    buf = buf or 0
    local buf_name = vim.api.nvim_buf_get_name(buf)
    return string.match(buf_name, "^minifiles://%d+/(.*)")
  end

  local git_run = function(buf, cmd)
    vim.system(cmd, { cwd = get_branch(buf) }, function(out)
      vim.schedule(function()
        if out.code == 0 and MiniFilesStatus then
          MiniFilesStatus.synchronize()
        end
        if string.match(vim.api.nvim_get_mode().mode, "[vV\22]") then
          vim.api.nvim_input("<Esc>")
        end
      end)
    end)
  end

  local get_entry_status = function(buf, lnum)
    assert(MiniFilesStatus and MiniFilesStatus.get_status, "`MiniFilesStatus.get_status` is not available")
    local fs_entry = MiniFiles.get_fs_entry(buf, lnum)
    if not fs_entry then
      return nil
    end
    return MiniFilesStatus.get_status(fs_entry.path), fs_entry
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

  Action.git_toggle_stage = function()
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
      git_run(0, { "git", "restore", "--staged", unpack(selected_paths) })
    else
      git_run(0, { "git", "add", unpack(selected_paths) })
    end
  end

  Action.git_restore = function()
    local selected_paths = get_selected_paths()
    git_run(0, { "git", "restore", unpack(selected_paths) })
  end

  Action.git_goto = function(dir)
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

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    desc = "Define `mini.files` buffer keymaps",
    group = au,
    callback = function(e)
      local buf_map = function(modes, lhs, rhs, opts) ---@param opts? vim.keymap.set.Opts
        opts = opts or {}
        opts.buf = e.data.buf_id
        vim.keymap.set(modes, lhs, rhs, opts)
      end
      -- stylua: ignore start
      buf_map("n", "m", function() Action.mark_set() end, { desc = "Set mark" })
      buf_map("n", "g~", function() Action.set_cwd() end, { desc = "Set cwd" })
      buf_map("n", "gx", function() Action.ui_open() end, { desc = "OS open" })
      buf_map({ "n", "x" }, "gy", function() Action.yank_path() end, { desc = "Yank path" })
      buf_map("n", "<C-w>n", function() Action.split("belowright horizontal") end, { desc = "Split horizontal" })
      buf_map("n", "<C-w>v", function() Action.split("belowright vertical") end, { desc = "Split vertical" })
      buf_map("n", "<C-w>t", function() Action.split("tab") end, { desc = "Split tab" })
      buf_map("n", "<M-i>", function() Action.toggle_hidden() end, { desc = "Toggle hidden" })
      buf_map("n", "<M-p>", function() Action.toggle_preview() end, { desc = "Toggle preview" })
      buf_map("n", "<C-b>", function() Action.norm_in_preview("<C-u>") end, { desc = "Scroll preview backwards" })
      buf_map("n", "<C-f>", function() Action.norm_in_preview("<C-d>") end, { desc = "Scroll preview upwards" })
      buf_map("n", "<C-g>", function() Action.jump_edges() end, { desc = "Jump edges" })
      buf_map("n", "<C-^>", function() Action.edit_alt() end, { desc = "Edit alternate" })
      buf_map("n", "<LocalLeader>sg", function() Action.minipick.search_grep() end, { desc = "Search grep" })
      buf_map("n", "<LocalLeader>sf", function() Action.minipick.search_files() end, { desc = "Search files" })
      buf_map({ "n", "x" }, "gh", function() Action.git_toggle_stage() end, { desc = "Git stage/unstage" })
      buf_map({ "n", "x" }, "gH", function() Action.git_restore() end, { desc = "Git restore" })
      buf_map({ "n", "x" }, "[h", function() Action.git_goto("prev") end, { desc = "Git goto previous" })
      buf_map({ "n", "x" }, "]h", function() Action.git_goto("next") end, { desc = "Git goto next" })
      buf_map({ "n", "x" }, "[H", function() Action.git_goto("first") end, { desc = "Git goto first" })
      buf_map({ "n", "x" }, "]H", function() Action.git_goto("last") end, { desc = "Git goto last" })
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesExplorerOpen",
    desc = "Define `mini.files` bookmarks (supports file bookmarks)",
    group = au,
    callback = function()
      local target_win = MiniFiles.get_explorer_state().target_window
      local target_buf = vim.api.nvim_win_get_buf(target_win)
      set_bookmark("%", vim.api.nvim_buf_get_name(target_buf), { desc = "Target file" })
      set_bookmark("@", vim.fn.getcwd, { desc = "Cwd" })
      set_bookmark("~", vim.fn.getcwd, { desc = "Cwd" })
      set_bookmark("n", vim.fn.stdpath("config") .. "/init.lua", { desc = "Config" })
      set_bookmark("p", vim.fn.stdpath("data") .. "/site/pack/core/opt", { desc = "Plugins" })
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    desc = "Ensure `mini.clue` triggers work with `mini.files`",
    group = au,
    callback = function(e)
      if MiniClue then
        MiniClue.ensure_buf_triggers(e.data.buf_id)
      end
    end,
  })

  -- Win options

  local format_size = function(stat)
    local bytes = stat.size
    local units = { "B", "KB", "MB", "GB" }
    for _, unit in ipairs(units) do
      if bytes < 1024 then
        local fmt = string.format("%.2f", bytes)
        fmt = fmt:gsub("%.00$", ""):gsub("(%..[1-9])0$", "%1")
        return fmt .. " " .. unit
      end
      bytes = bytes / 1024
    end
  end

  local format_time = function(stat)
    local sec = stat.mtime.sec
    return os.date("%Y-%m-%d %H:%M", sec)
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesWindowUpdate",
    desc = "Set `mini.files` options",
    group = au,
    callback = function(e)
      local win = e.data.win_id
      local buf = e.data.buf_id
      local is_preview = win == get_preview_win()
      local _, stat = buf_get_path(buf)
      local is_file = stat and stat.type == "file"
      if is_preview then
        if is_file then
          vim.wo[win].number = true
          vim.wo[win].conceallevel = 0
        end
        -- NOTE: Display status in the top-right corner of the preview window
        if stat then
          local config = vim.api.nvim_win_get_config(win)
          local left = vim.tbl_get(config, "title", 1, 1) or ""
          local right = string.format(" %s | %s ", format_size(stat), format_time(stat))
          local pad_sym = vim.tbl_get(config, "border", 2) or " "
          local pad = string.rep(pad_sym, math.max(1, config.width - #left - #right))
          vim.api.nvim_win_set_config(win, { title = { { left }, { pad }, { right } } })
        end
      else
        vim.wo[win].number = true
        vim.wo[win].relativenumber = true
        vim.wo[win].cursorline = true
      end
    end,
  })

  -- Resize preview

  local refresh_preview = function()
    local width_focus = MiniFiles.config.windows.width_focus
    local width_preview = MiniFiles.config.windows.width_preview
    local preview_width = math.min(vim.o.columns - width_focus - 4, width_preview)
    MiniFiles.refresh({ windows = { width_preview = preview_width } })
  end

  local resize_desc = "Resize `mini.files` preview to be always visible"
  vim.api.nvim_create_autocmd("VimResized", {
    group = au,
    desc = resize_desc,
    callback = function()
      refresh_preview()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesWindowOpen",
    group = au,
    desc = resize_desc,
    callback = function()
      vim.schedule(function()
        refresh_preview()
      end)
    end,
  })

  -- Custom preview: extend lines

  local ns_preview = vim.api.nvim_create_namespace("minifiles_better_preview")

  local validate_file = function(path)
    local fd, _, err = vim.uv.fs_open(path, "r", 1)
    if not fd then
      return err, nil
    end
    local is_binary = vim.uv.fs_read(fd, 1024):find("\0") ~= nil
    vim.uv.fs_close(fd)
    return false, is_binary
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferUpdate",
    desc = "Extend `mini.files` preview lines; adjust preview error display",
    callback = function(e)
      local buf = e.data.buf_id
      local path, stat = buf_get_path(buf)
      if not stat or stat.type == "directory" then
        return
      end
      local extm_id = 1
      local error = function(msg)
        local hl = "Text"
        vim.treesitter.stop(buf)
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
        vim.api.nvim_buf_set_extmark(buf, ns_preview, 0, 0, {
          id = extm_id,
          virt_text_pos = "overlay",
          virt_text = { { msg, hl } },
        })
      end
      local warn = function(msg)
        local hl = "WarningMsg"
        vim.api.nvim_buf_set_extmark(buf, ns_preview, 0, 0, {
          id = extm_id,
          virt_text_pos = "right_align",
          virt_text = { { msg, hl } },
        })
      end
      local no_access, is_binary = validate_file(path)
      local format_msg = function(msg)
        msg = " " .. msg .. string.rep(" ", MiniFiles.config.windows.width_preview)
        return string.gsub(msg, " ", "-")
      end
      if no_access then
        error(format_msg("No access"))
        return
      end
      if is_binary then
        error(format_msg("Non text file"))
        return
      end
      if stat.size > 512 * 1024 then
        warn("Large file detected (>512KB)")
        return
      end
      local read_ok, read_lines = pcall(vim.fn.readfile, path, "")
      if read_ok then
        -- NOTE: Remove '\n', which may appear in binary files
        local lines = vim.split(table.concat(read_lines, "\n"), "\n")
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      end
    end,
  })
end)
