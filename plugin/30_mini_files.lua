local pack = require("util.pack")

pack.later(function()
  local MiniFiles = require("mini.files")

  local files_au = vim.api.nvim_create_augroup("minifiles", { clear = true })

  MiniFiles.setup({
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
    local state = MiniFiles.get_explorer_state()
    if not state then
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

  local get_selected = function()
    local mode = vim.api.nvim_get_mode().mode
    local is_visual = mode == "v" or mode == "V" or mode == vim.keycode("<C-v>")
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local ln_range = { row, row }
    if is_visual then
      local row_start, row_end = row, vim.fn.line("v")
      ln_range = { math.min(row_start, row_end), math.max(row_start, row_end) }
    end
    local selected = {}
    for ln = ln_range[1], ln_range[2] do
      local fs_entry = MiniFiles.get_fs_entry(0, ln)
      if fs_entry then
        table.insert(selected, fs_entry)
      end
    end
    return selected
  end

  -- Keymaps

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

  local mark_set = function()
    local id = vim.fn.getcharstr()
    if not id or id == "" or id == "\27" then
      return
    end
    local path = MiniFiles.get_fs_entry().path
    set_bookmark(id, path)
    vim.notify("Bookmark " .. vim.inspect(id) .. " is set")
  end

  local show_hidden = true

  local toggle_hidden = function()
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

  local ui_open = function()
    vim.ui.open(MiniFiles.get_fs_entry().path)
  end

  local set_cwd = function()
    local path = (MiniFiles.get_fs_entry() or {}).path
    if path == nil then
      return vim.notify("Cursor is not on valid entry")
    end
    vim.fn.chdir(vim.fs.dirname(path))
  end

  local yank_path = function()
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
    local register = vim.v.register
    local selected = get_selected()
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

  local toggle_preview = function()
    local is_preview = MiniFiles.config.windows.preview
    local is_preview_next = not is_preview
    MiniFiles.config.windows.preview = is_preview_next
    MiniFiles.trim_right()
    MiniFiles.refresh({ windows = { preview = is_preview_next } })
    if is_preview then
      local branch = MiniFiles.get_explorer_state().branch
      table.remove(branch)
      MiniFiles.set_branch(branch)
    end
  end

  local norm_in_preview = function(keys)
    preview_win_call(function()
      local key = vim.api.nvim_replace_termcodes(keys, true, false, true)
      vim.cmd.norm({ key, bang = true })
    end)
  end

  local jump_edges = function()
    preview_win_call(function()
      local last = vim.fn.line(".") == vim.fn.line("$")
      vim.cmd.norm({ last and "gg" or "G", bang = true })
    end)
  end

  local split = function(dir)
    local fs_entry = MiniFiles.get_fs_entry()
    if fs_entry.fs_type == "directory" then
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

  local alt_entry = nil

  local new_alt = function()
    local exp_state = MiniFiles.get_explorer_state()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local row_count = vim.api.nvim_buf_line_count(0)
    local path
    for i = 0, row_count - 1 do
      local ln = (row + i - 1) % row_count + 1
      local fs_entry = MiniFiles.get_fs_entry(0, ln) or {}
      if fs_entry.path then
        path = fs_entry.path
        break
      end
    end
    return {
      branch = exp_state.branch,
      depth_focus = exp_state.depth_focus,
      cursor_path = path,
    }
  end

  local edit_alt = function()
    if alt_entry then
      local curr_alt_entry = new_alt()
      MiniFiles.set_branch(alt_entry.branch, { depth_focus = alt_entry.depth_focus })
      if alt_entry.cursor_path then
        pcall(set_cursor_path, alt_entry.cursor_path)
      end
      alt_entry = curr_alt_entry
    end
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesExplorerClose",
    desc = "Save `mini.files` alternate entry on close",
    group = files_au,
    callback = function()
      alt_entry = new_alt()
    end,
  })

  local search_grep = function()
    local MiniPick = require("mini.pick")
    local entry = MiniFiles.get_fs_entry()
    if not entry then
      return
    end
    local parent = vim.fn.fnamemodify(entry.path, ":h")
    MiniPick.registry.grep({ pattern = "." }, { source = { cwd = parent } })
  end

  local search_files = function()
    local MiniPick = require("mini.pick")
    local entry = MiniFiles.get_fs_entry()
    if not entry then
      return
    end
    local parent = vim.fn.fnamemodify(entry.path, ":h")
    MiniPick.registry.files(nil, { source = { cwd = parent } })
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesExplorerOpen",
    desc = "Define `mini.files` bookmarks (supports file bookmarks)",
    group = files_au,
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
    desc = "Define `mini.files` buffer keymaps",
    group = files_au,
    callback = function(e)
      local buf_map = function(mode, lhs, rhs, opts)
        opts = vim.tbl_extend("keep", opts or {}, { buffer = e.data.buf_id })
        vim.keymap.set(mode, lhs, rhs, opts)
      end
      -- stylua: ignore start
      buf_map("n", "m", function() mark_set() end, { desc = "Set mark" })
      buf_map("n", "g.", function() toggle_hidden() end, { desc = "Toggle hiddent" })
      buf_map("n", "gx", function() ui_open() end, { desc = "OS open" })
      buf_map("n", "g~", function() set_cwd() end, { desc = "Set cwd" })
      buf_map({ "n", "v" }, "gy", function() yank_path() end, { desc = "Yank path" })
      buf_map("n", "<M-p>", function() toggle_preview() end, { desc = "Toggle preview" })
      buf_map("n", "<C-b>", function() norm_in_preview("<C-u>") end, { desc = "Scroll preview backwards" })
      buf_map("n", "<C-f>", function() norm_in_preview("<C-d>") end, { desc = "Scroll preview upwards" })
      buf_map("n", "<C-g>", function() jump_edges() end, { desc = "Jump edges" })
      buf_map("n", "<M-n>", function() split("belowright horizontal") end, { desc = "Split horizontal" })
      buf_map("n", "<M-v>", function() split("belowright vertical") end, { desc = "Split vertical" })
      buf_map("n", "<M-t>", function() split("tab") end, { desc = "Split tab" })
      buf_map("n", "<C-^>", function() edit_alt() end, { desc = "Edit alternate" })
      buf_map("n", "<Leader>sg", function() search_grep() end, { desc = "Search grep" })
      buf_map("n", "<Leader>sf", function() search_files() end, { desc = "Search files" })
    end,
  })

  -- Win options

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesWindowUpdate",
    desc = "Set `mini.files` 'number' option",
    group = files_au,
    callback = function(e)
      local win = e.data.win_id
      local buf = e.data.buf_id
      local is_preview = win == get_preview_win()
      local _, stat = buf_get_path(buf)
      local is_dir = stat and stat.type == "directory"
      vim.wo[win].number = not (is_preview and is_dir)
      vim.wo[win].relativenumber = not is_preview
      vim.wo[win].cursorline = not is_preview
    end,
  })

  -- Resize preview

  local refresh_preview = function()
    local width_focus = MiniFiles.config.windows.width_focus
    local width_preview = MiniFiles.config.windows.width_preview
    local preview_width = math.min(vim.o.columns - width_focus - 4, width_preview)
    MiniFiles.refresh({ windows = { width_preview = preview_width } })
  end

  local resize_autocmd = function(event, opts)
    vim.api.nvim_create_autocmd(
      event,
      vim.tbl_extend("keep", opts, { desc = "Resize `mini.files` preview to be always visible", group = files_au })
    )
  end

  resize_autocmd("VimResized", { callback = refresh_preview })
  resize_autocmd("User", { pattern = "MiniFilesWindowOpen", callback = vim.schedule_wrap(refresh_preview) })

  -- Custom preview: extend lines

  local validate_file = function(path)
    local fd, _, err = vim.uv.fs_open(path, "r", 1)
    if not fd then
      return err, nil
    end
    local is_binary = vim.uv.fs_read(fd, 1024):find("\0") ~= nil
    vim.uv.fs_close(fd)
    return false, is_binary
  end

  local files_preview_ns = vim.api.nvim_create_namespace("minifiles")

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferUpdate",
    desc = "Extend `mini.files` preview lines; adjust preview error display",
    callback = function(args)
      local buf = args.data.buf_id
      local path, stat = buf_get_path(buf)
      if not stat or stat.type == "directory" then
        return
      end
      local extm_id = 1
      local error = function(msg)
        local hl = "Text"
        vim.treesitter.stop(buf)
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
        vim.api.nvim_buf_set_extmark(buf, files_preview_ns, 0, 0, {
          id = extm_id,
          virt_text_pos = "overlay",
          virt_text = { { msg, hl } },
        })
      end
      local warn = function(msg)
        local hl = "WarningMsg"
        vim.api.nvim_buf_set_extmark(buf, files_preview_ns, 0, 0, {
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
        local lines = vim.split(table.concat(read_lines, "\n"), "\n")
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      end
    end,
  })
end)
