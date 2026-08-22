-- See https://github.com/nvim-mini/mini.nvim/discussions/2238
local pack = require("util.pack")
local mini_files = require("shared.mini_files")

_G.MiniClue = _G.MiniClue

pack.plug(function()
  local MiniFiles = require("mini.files")

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

  -- Keymaps

  -- stylua: ignore start
  vim.keymap.set("n", "<Leader>F", function() MiniFiles.open() end, { desc = "Open files" })
  vim.keymap.set("n", "<Leader>.F", function() MiniFiles.open(vim.fn.expand("%:p")) end, { desc = "Open files (buf)" })
  vim.keymap.set("n", "<Leader>@F", function() MiniFiles.open(vim.fn.getcwd()) end, { desc = "Open files (cwd)" })
  vim.keymap.set("n", "<Leader>~F", function() MiniFiles.open("~") end, { desc = "Open files (system home)" })
  -- stylua: ignore end
  local au_keys = vim.api.nvim_create_augroup("config/minifiles.keymaps", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    group = au_keys,
    desc = "Define `mini.files` buffer keymaps",
    callback = function(e)
      local buf_map = function(modes, lhs, rhs, opts) ---@param opts? vim.keymap.set.Opts
        opts = opts or {}
        opts.buf = e.data.buf_id
        vim.keymap.set(modes, lhs, rhs, opts)
      end
      -- stylua: ignore start
      buf_map("n", "m", function() mini_files.actions.mark_set() end, { desc = "Set mark" })
      buf_map("n", "g~", function() mini_files.actions.set_cwd() end, { desc = "Set cwd" })
      buf_map("n", "gx", function() mini_files.actions.ui_open() end, { desc = "OS open" })
      buf_map({ "n", "x" }, "gy", function() mini_files.actions.yank_path() end, { desc = "Yank path" })
      buf_map("n", "<C-w>n", function() mini_files.actions.split("belowright horizontal") end, { desc = "Split horizontal" })
      buf_map("n", "<C-w>v", function() mini_files.actions.split("belowright vertical") end, { desc = "Split vertical" })
      buf_map("n", "<C-w>t", function() mini_files.actions.split("tab") end, { desc = "Split tab" })
      buf_map("n", "<M-i>", function() mini_files.actions.toggle_hidden() end, { desc = "Toggle hidden" })
      buf_map("n", "<M-p>", function() mini_files.actions.toggle_preview() end, { desc = "Toggle preview" })
      buf_map("n", "<C-b>", function() mini_files.actions.norm_in_preview("<C-u>") end, { desc = "Scroll preview backwards" })
      buf_map("n", "<C-f>", function() mini_files.actions.norm_in_preview("<C-d>") end, { desc = "Scroll preview upwards" })
      buf_map("n", "<C-g>", function() mini_files.actions.jump_edges() end, { desc = "Jump edges" })
      buf_map("n", "<C-^>", function() mini_files.actions.edit_alt() end, { desc = "Edit alternate" })
      buf_map("n", "<LocalLeader>sg", function() mini_files.actions.minipick.search_grep() end, { desc = "Search grep" })
      buf_map("n", "<LocalLeader>sf", function() mini_files.actions.minipick.search_files() end, { desc = "Search files" })
      buf_map({ "n", "x" }, "gh", function() mini_files.actions.git_toggle_stage() end, { desc = "Git stage/unstage" })
      buf_map({ "n", "x" }, "gH", function() mini_files.actions.git_restore() end, { desc = "Git restore" })
      buf_map({ "n", "x" }, "[h", function() mini_files.actions.git_goto("prev") end, { desc = "Git goto previous" })
      buf_map({ "n", "x" }, "]h", function() mini_files.actions.git_goto("next") end, { desc = "Git goto next" })
      buf_map({ "n", "x" }, "[H", function() mini_files.actions.git_goto("first") end, { desc = "Git goto first" })
      buf_map({ "n", "x" }, "]H", function() mini_files.actions.git_goto("last") end, { desc = "Git goto last" })
    end,
  })

  -- Bookmarks

  local au_marks = vim.api.nvim_create_augroup("config/minifiles.bookmarks", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesExplorerOpen",
    group = au_marks,
    desc = "Define `mini.files` bookmarks (supports file bookmarks)",
    callback = function()
      local target_win = MiniFiles.get_explorer_state().target_window
      local target_buf = vim.api.nvim_win_get_buf(target_win)
      mini_files.set_bookmark("%", vim.api.nvim_buf_get_name(target_buf), { desc = "Target file" })
      mini_files.set_bookmark("@", vim.fn.getcwd, { desc = "Cwd" })
      mini_files.set_bookmark("~", vim.fn.getcwd, { desc = "Cwd" })
      mini_files.set_bookmark("n", vim.fn.stdpath("config") .. "/init.lua", { desc = "Config" })
      mini_files.set_bookmark("p", vim.fn.stdpath("data") .. "/site/pack/core/opt", { desc = "Plugins" })
    end,
  })

  -- Ensure `mini.clue`

  local au_clue = vim.api.nvim_create_augroup("config/minifiles.clue", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    group = au_clue,
    desc = "Ensure `mini.clue` triggers work with `mini.files`",
    callback = function(e)
      if MiniClue then
        MiniClue.ensure_buf_triggers(e.data.buf_id)
      end
    end,
  })

  -- Show numbers

  local au_num = vim.api.nvim_create_augroup("config/minifiles.numbers", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesWindowUpdate",
    group = au_num,
    desc = "Show line numbers in `mini.files` windows",
    callback = function(e)
      local win, buf = e.data.win_id, e.data.buf_id
      local is_preview = win == mini_files.get_preview_win()
      local stat = vim.uv.fs_stat(mini_files.get_branch(buf))
      if is_preview then
        if stat and stat.type == "file" then
          vim.wo[win].number = true
          vim.wo[win].conceallevel = 0
        end
      else
        vim.wo[win].number = true
        vim.wo[win].relativenumber = true
        vim.wo[win].cursorline = true
      end
    end,
  })

  -- Show preview stat

  local au_stat = vim.api.nvim_create_augroup("config/minifiles.preview_stat", { clear = true })
  local format_size = function(stat)
    local bytes = stat.size
    local units = { "B", "KB", "MB", "GB" }
    for i, unit in ipairs(units) do
      if bytes < 1024 or i == #units then
        local unit_size = ("%.2f"):format(bytes):gsub("%.?0+$", "")
        return string.format("%s %s", unit_size, unit)
      end
      bytes = bytes / 1024
    end
  end
  local format_time = function(stat)
    return os.date("%Y-%m-%d %H:%M", stat.mtime.sec)
  end
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesWindowUpdate",
    group = au_stat,
    desc = "Update `mini.files` preview stat at the top corner",
    callback = function(e)
      local win, buf = e.data.win_id, e.data.buf_id
      local is_preview = win == mini_files.get_preview_win()
      local stat = vim.uv.fs_stat(mini_files.get_branch(buf))
      if not (is_preview and stat) then
        return
      end
      local config = vim.api.nvim_win_get_config(win)
      local left = vim.tbl_get(config, "title", 1, 1) or ""
      local right = string.format(" %s | %s ", format_size(stat), format_time(stat))
      local pad_sym = vim.tbl_get(config, "border", 2) or " "
      local pad = string.rep(pad_sym, math.max(1, config.width - #left - #right))
      vim.api.nvim_win_set_config(win, { title = { { left }, { pad }, { right } } })
    end,
  })

  -- Resize preview

  local au_resize = vim.api.nvim_create_augroup("config/minifiles.resize_preview", { clear = true })
  local refresh_preview = function()
    local width_focus = MiniFiles.config.windows.width_focus
    local width_preview = MiniFiles.config.windows.width_preview
    local preview_width = math.min(vim.o.columns - width_focus - 4, width_preview)
    MiniFiles.refresh({ windows = { width_preview = preview_width } })
  end
  local desc = "Resize `mini.files` preview to be always visible"
  vim.api.nvim_create_autocmd("VimResized", {
    group = au_resize,
    desc = desc,
    callback = function()
      refresh_preview()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesWindowOpen",
    group = au_resize,
    desc = desc,
    callback = vim.schedule_wrap(function()
      refresh_preview()
    end),
  })

  -- Custom preview: whole file

  local au_preview = vim.api.nvim_create_augroup("config/minifiles.custom_preview", { clear = true })
  local ns_preview = vim.api.nvim_create_namespace("config/minifiles.custom_preview")
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
    group = au_preview,
    desc = "Extend `mini.files` preview lines; adjust preview error display",
    callback = function(e)
      local buf = e.data.buf_id
      local path = assert(mini_files.get_branch(buf))
      local stat = assert(vim.uv.fs_stat(path))
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
