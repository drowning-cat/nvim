vim.g.project_dirs = vim.F.if_nil(vim.g.project_dirs, {})
vim.g.project_maxdepth = vim.F.if_nil(vim.g.project_maxdepth, 3)

local pick_share = require("share.plugin.mini_pick")

local pack = require("util.pack")
local util_root = require("util.root")

local find_projects = util_root.find_projects

-- Pick

pack.now(function()
  local MiniPick = require("mini.pick")
  local MiniExtra = require("mini.extra")

  -- Overrides (colors)

  for name, gen_show in pairs(pick_share.gen_show) do
    local pick = MiniPick.builtin[name] or MiniExtra.pickers[name]
    MiniPick.registry[name] = function(local_opts, opts)
      local show = gen_show(local_opts)
      opts = vim.tbl_deep_extend("keep", opts or {}, { source = { show = show } })
      return pick(local_opts, opts)
    end
  end

  MiniPick.registry.git_hunks = function(local_opts, opts)
    local choose_marked = function(items)
      if vim.tbl_isempty(items) then
        items = { MiniPick.get_picker_matches().current }
      end
      local patches = {}
      for _, item in ipairs(items) do
        vim.list_extend(patches, item.header)
        vim.list_extend(patches, item.hunk)
      end
      local cmd = { "git", "apply", "--cached" }
      if local_opts.scope == "staged" then
        table.insert(cmd, "--reverse")
      end
      vim.system(cmd, { stdin = patches })
    end
    local show = pick_share.gen_show.git_hunks()
    opts = vim.tbl_deep_extend("keep", opts or {}, {
      source = {
        show = show,
        choose_marked = choose_marked,
      },
    })
    return MiniExtra.pickers.git_hunks(local_opts, opts)
  end

  MiniPick.registry.grep_live = function(local_opts, opts)
    local_opts = vim.tbl_extend("keep", local_opts or {}, { globs = {} })
    opts = vim.tbl_extend("keep", opts or {}, { source = {} })
    local cwd = vim.fs.abspath(opts.source.cwd or vim.fn.getcwd())
    local set_items_opts = { do_match = false, querytick = MiniPick.get_querytick() }
    local rg_cmd = function(pattern, globs)
      local cmd =
        { "rg", "--column", "--line-number", "--no-heading", "--field-match-separator", "\\x00", "--color=never" }
      for _, g in ipairs(globs) do
        vim.list_extend(cmd, { "--glob", g })
      end
      local case = vim.o.ignorecase and (vim.o.smartcase and "smart-case" or "ignore-case") or "case-sensitive"
      vim.list_extend(cmd, { "--" .. case })
      vim.list_extend(cmd, { "--", pattern })
      return cmd
    end
    local parse_globs = function(query_str)
      local escape = function(str)
        return str:gsub("\\ ", "\1")
      end
      local unescape = function(str)
        return str:gsub("\1", "\\ ")
      end
      local after_split = vim.split(escape(query_str), "%s+", { trimempty = true })
      return vim.tbl_map(unescape, after_split)
    end
    local glob_mode = false
    local glob_query = {}
    local pattern_query = {}
    local query_globs = {}
    local globs = {}
    local process
    local match = function(_, _, query)
      pcall(vim.uv.process_kill, process)
      if MiniPick.get_querytick() == set_items_opts.querytick then
        return
      end
      if glob_mode then
        glob_query = query
        query_globs = parse_globs(table.concat(query))
        globs = {}
        vim.list_extend(globs, local_opts.globs)
        vim.list_extend(globs, query_globs)
      else
        pattern_query = query
      end
      if vim.tbl_isempty(pattern_query) and vim.tbl_isempty(query_globs) then
        return MiniPick.set_picker_items({}, set_items_opts)
      end
      set_items_opts.querytick = MiniPick.get_querytick()
      local cmd = rg_cmd(table.concat(pattern_query), globs)
      process = MiniPick.set_picker_items_from_cli(cmd, { set_items_opts = set_items_opts, spawn_opts = { cwd = cwd } })
    end
    local toggle_glob = function()
      glob_mode = not glob_mode
      if glob_mode then
        MiniPick.set_picker_opts({ source = { name = "Grep live (rg*)" } })
        MiniPick.set_picker_query(glob_query)
      else
        local suffix = vim.tbl_isempty(globs) and "" or " | " .. table.concat(globs, ", ")
        local source_name = string.format("Grep live (rg%s)", suffix)
        MiniPick.set_picker_opts({ source = { name = source_name } })
        MiniPick.set_picker_query(pattern_query)
      end
    end
    local show = pick_share.gen_show.grep_live()
    return MiniPick.start(vim.tbl_deep_extend("force", opts, {
      source = {
        name = "Grep live (rg)",
        items = {},
        match = match,
        show = show,
      },
      mappings = {
        toggle_glob = { char = "<C-o>", func = toggle_glob },
      },
    }))
  end

  -- Overrides (other)

  MiniPick.registry.colorschemes = function(local_opts, opts)
    local fake_buf = vim.api.nvim_create_buf(false, true)
    local au = vim.api.nvim_create_augroup("pick_colors", { clear = true })
    local cl = vim.g.colors_name or "default"
    local bg = vim.o.background or "dark"
    local preview = function(colors)
      local matches = MiniPick.get_picker_matches()
      if matches then
        local item = colors or matches.current
        local func = MiniPick.get_picker_opts().source.preview
        pcall(func, fake_buf, item)
        vim.o.background = bg
      end
    end
    local match_current = function()
      local matches = MiniPick.get_picker_matches()
      local current = vim.iter(matches.all_inds):find(function(i)
        return cl == matches.all[i]
      end)
      if current then
        MiniPick.set_picker_match_inds({ current }, "current")
      end
    end
    local on_move = function()
      vim.schedule(preview)
    end
    vim.api.nvim_create_autocmd("User", { pattern = "MiniPickStart", group = au, callback = match_current })
    vim.api.nvim_create_autocmd("User", { pattern = "MiniPickMatch", group = au, callback = on_move })
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniPickStop",
      group = au,
      once = true,
      callback = function()
        vim.api.nvim_clear_autocmds({ group = au })
        vim.api.nvim_buf_delete(fake_buf, { unload = true })
      end,
    })
    local remap_move = function(char, keys)
      return {
        char = char,
        func = function()
          vim.api.nvim_input(keys)
          on_move()
        end,
      }
    end
    return MiniExtra.pickers.colorschemes(
      local_opts,
      vim.tbl_deep_extend("keep", opts or {}, {
        source = {
          choose = function(item)
            vim.cmd.colorscheme(item)
            vim.g.COLORS_NAME = vim.g.colors_name
            vim.g.COLORS_BG = vim.o.background
            vim.cmd.wshada()
          end,
        },
        mappings = {
          match_current = {
            char = "<C-0>",
            func = function()
              match_current()
              on_move()
            end,
          },
          change_bg = {
            char = "<C-o>",
            func = function()
              bg = vim.o.background == "dark" and "light" or "dark"
              vim.o.background = bg
            end,
          },
          move_start = "<C-Home>",
          scroll_down = "<PageDown>",
          scroll_up = "<PageUp>",
          move_start_alt = remap_move("<C-g>", "<C-Home>"),
          move_down = "",
          move_up = "",
          move_down_alt = remap_move("<C-n>", "<Down>"),
          move_up_alt = remap_move("<C-p>", "<Up>"),
          move_down_2_alt = remap_move("<C-j>", "<Down>"),
          move_up_2_alt = remap_move("<C-k>", "<Up>"),
          scroll_down_alt = remap_move("<C-f>", "<PageDown>"),
          scroll_up_alt = remap_move("<C-b>", "<PageUp>"),
        },
      })
    )
  end

  local minifiles_open = function(...)
    local path = vim.fs.joinpath(...)
    local ok, MiniFiles = pcall(require, "mini.files")
    if not ok then
      return false
    end
    vim.schedule(function()
      MiniFiles.open(path, true)
    end)
    return true
  end

  local fd_cmd = function(type)
    type = type or "f"
    return { "fd", "-t" .. type, "-H", "-I", "-E=.git", "-E=node_modules" }
  end

  MiniPick.registry.files = function(_, opts)
    local cli_opts = { command = fd_cmd("f") }
    local show = function(buf, items, query)
      MiniPick.default_show(buf, items, query, { show_icons = true })
    end
    return MiniPick.builtin.cli(
      cli_opts,
      vim.tbl_deep_extend("keep", opts or {}, {
        source = {
          name = "Files (fd)",
          show = show,
        },
        mappings = {
          browse = {
            char = "<S-Enter>",
            func = function()
              local item = MiniPick.get_picker_matches().current
              local path = item
              local cwd = vim.tbl_get(opts, "source", "cwd")
              return minifiles_open(cwd, path)
            end,
          },
        },
      })
    )
  end

  MiniPick.registry.directories = function(_, opts)
    local cli_opts = { command = fd_cmd("d") }
    local show = function(buf, items, query)
      MiniPick.default_show(buf, items, query, { show_icons = true })
    end
    return MiniPick.builtin.cli(
      cli_opts,
      vim.tbl_deep_extend("keep", opts or {}, {
        source = {
          name = "Directories (fd)",
          show = show,
        },
      })
    )
  end

  -- New pickers

  MiniPick.registry.grep_todo = function(local_opts, opts)
    local grep_words = { "FIX", "FIXME", "BUG", "NOTE", "TODO", "FEAT", "WARN", "WARNING", "HACK", "PERF" }
    local pattern = "(" .. table.concat(grep_words, "|") .. ")[ :]"
    local_opts = vim.tbl_extend("keep", local_opts or {}, { pattern = pattern })
    return MiniPick.registry.grep(local_opts, opts)
  end

  MiniPick.registry.projects = function(local_opts, opts)
    local_opts = vim.tbl_extend("keep", local_opts or {}, { dirs = vim.g.project_dirs or {} })
    local show = function(buf, items, query)
      MiniPick.default_show(buf, items, query, { show_icons = true })
    end
    local found_projects = find_projects(local_opts.dirs, vim.g.project_maxdepth)
    local items = vim.tbl_map(function(project)
      local path, root = project.path, project.root
      return {
        fs_type = "directory",
        path = path,
        text = vim.fs.basename(root) .. ":" .. vim.fs.relpath(root, path),
      }
    end, found_projects)
    local choose = function(item)
      vim.schedule(function()
        MiniPick.registry.files(nil, { source = { cwd = item.path } })
      end)
    end
    return MiniPick.start(vim.tbl_deep_extend("keep", opts or {}, {
      source = {
        name = "Projects",
        items = items,
        show = show,
        choose = choose,
      },
      mappings = {
        browse = {
          char = "<S-Enter>",
          func = function()
            local item = MiniPick.get_picker_matches().current
            local path = item.path
            return minifiles_open(path)
          end,
        },
      },
    }))
  end

  -- Setup

  local run_keys = function(keys, rep)
    vim.api.nvim_input(string.rep(keys, rep or 1))
  end

  local pick_move_caret = function(next_caret)
    local caret = MiniPick.get_picker_state().caret
    local query = MiniPick.get_picker_query()
    next_caret = math.max(1, math.min(next_caret, #query + 1))
    local move = next_caret - caret
    run_keys(move >= 0 and "<Right>" or "<Left>", math.abs(move))
  end

  local pick_remap = function(char, keys)
    return {
      char = char,
      func = function()
        run_keys(keys)
      end,
    }
  end

  MiniPick.setup({
    mappings = {
      choose_marked = "<C-Enter>",
      quickfix = {
        char = "<C-q>",
        func = function()
          local no_items_call = function()
            vim.notify("(mini.pick) Unable to set quickfix list", vim.log.levels.WARN)
            return true -- Close
          end
          MiniPick.set_picker_opts({ source = { choose = no_items_call } })
          local marked = MiniPick.get_picker_matches().marked
          local items = vim.tbl_isempty(marked) and MiniPick.get_picker_items() or marked
          MiniPick.default_choose_marked(items, { list_type = "quickfix" })
          return true
        end,
      },
      caret_start = {
        char = "<Home>",
        func = function()
          pick_move_caret(1)
        end,
      },
      caret_end = {
        char = "<End>",
        func = function()
          pick_move_caret(math.huge)
        end,
      },
      prev_word = {
        char = "<C-Left>",
        func = function()
          local query_str = table.concat(MiniPick.get_picker_query())
          local caret = MiniPick.get_picker_state().caret
          local regex = vim.regex([=[\([^[:keyword:][:space:]]\+\|\k\+\)\s*$]=])
          local from, _ = regex:match_str(string.sub(query_str, 1, caret - 1))
          pick_move_caret(from and from + 1 or 1)
        end,
      },
      next_word = {
        char = "<C-Right>",
        func = function()
          local query_str = table.concat(MiniPick.get_picker_query())
          local caret = MiniPick.get_picker_state().caret
          local regex = vim.regex([=[^\([^[:keyword:][:space:]]\+\|\k\+\)\s*]=])
          local _, to = regex:match_str(string.sub(query_str, caret))
          pick_move_caret(to and to + caret or math.huge)
        end,
      },
      prev_before_space = {
        char = "<S-Left>",
        func = function()
          local query_str = table.concat(MiniPick.get_picker_query())
          local caret = MiniPick.get_picker_state().caret
          local search_str = string.sub(query_str, 1, caret - 1)
          local word_start = string.find(search_str, "%S+%s*$")
          pick_move_caret(word_start or 1)
        end,
      },
      next_before_space = {
        char = "<S-Right>",
        func = function()
          local query_str = table.concat(MiniPick.get_picker_query())
          local caret = MiniPick.get_picker_state().caret
          local word_end = string.find(query_str, "%f[%s]", caret + 1)
          pick_move_caret(word_end or #query_str + 1)
        end,
      },
      move_down_alt = pick_remap("<C-j>", "<C-n>"),
      move_up_alt = pick_remap("<C-k>", "<C-p>"),
    },
  })

  -- stylua: ignore start
  local buf_name = function(buf) return vim.api.nvim_buf_get_name(buf or 0) end
  -- mini.pick
  vim.keymap.set("n", "<Leader>sb", function() MiniPick.registry.buffers() end, { desc = "Search buffers" })
  vim.keymap.set("n", "<Leader>sf", function() MiniPick.registry.files() end, { desc = "Search files" })
  vim.keymap.set("n", "<Leader>sF", function() MiniPick.registry.directories() end, { desc = "Search directories" })
  vim.keymap.set("n", "<Leader>sg", function() MiniPick.registry.grep_live() end, { desc = "Search grep" })
  vim.keymap.set("n", "<Leader>sh", function() MiniPick.registry.help() end, { desc = "Search help" })
  vim.keymap.set("n", "<Leader>sr", function() MiniPick.registry.resume() end, { desc = "Search resume" })
  -- mini.extra
  vim.keymap.set("n", "<Leader>sl", function() MiniPick.registry.buf_lines({ scope = "current" }) end, { desc = "Search lines (buf)" })
  vim.keymap.set("n", "<Leader>sL", function() MiniPick.registry.buf_lines({ scope = "all" }) end, { desc = "Search lines (all)" })
  vim.keymap.set("n", "<Leader>sa", function() MiniPick.registry.git_hunks({ path = buf_name(), scope = "staged" }) end, { desc = "Search added hunks (buf)" })
  vim.keymap.set("n", "<Leader>sA", function() MiniPick.registry.git_hunks({ scope = "staged" }) end, { desc = "Search added hunks (all)" })
  vim.keymap.set("n", "<Leader>sm", function() MiniPick.registry.git_hunks() end, { desc = "Search modified hunks (all)" })
  vim.keymap.set("n", "<Leader>sM", function() MiniPick.registry.git_hunks({ path = buf_name() }) end, { desc = "Search modified hunks (buf)" })
  vim.keymap.set("n", "<Leader>sc", function() MiniPick.registry.git_commits({ path = buf_name() }) end, { desc = "Search commits (buf)" })
  vim.keymap.set("n", "<Leader>sC", function() MiniPick.registry.git_commits() end, { desc = "Search commits (all)" })
  vim.keymap.set("n", "<Leader>sd", function() MiniPick.registry.diagnostic({ scope = "current" }) end, { desc = "Search diagnostics (buf)" })
  vim.keymap.set("n", "<Leader>sD", function() MiniPick.registry.diagnostic({ scope = "all" }) end, { desc = "Search diagnostics (workspace)" })
  vim.keymap.set("n", "<Leader>sR", function() MiniPick.registry.lsp({ scope = "references" }) end, { desc = "Search LSP refs" })
  vim.keymap.set("n", "<Leader>ss", function() MiniPick.registry.lsp({ scope = "document_symbol" }) end, { desc = "Search LSP symbols (doc)" })
  vim.keymap.set("n", "<Leader>sS", function() MiniPick.registry.lsp({ scope = "workspace_symbol_live" }) end, { desc = "Search LSP symbols (workspace)" })
  vim.keymap.set("n", "<Leader>sH", function() MiniPick.registry.hl_groups() end, { desc = "Search highlights" })
  vim.keymap.set("n", "<Leader>s/", function() MiniPick.registry.history({ scope = "/" }) end, { desc = "Search '/' history" })
  vim.keymap.set("n", "<Leader>s:", function() MiniPick.registry.history({ scope = ":" }) end, { desc = "Search cmd history" })
  vim.keymap.set("n", "<Leader>so", function() MiniPick.registry.colorschemes() end, { desc = "Search colorschemes" })
  vim.keymap.set("n", "<Leader>s'", function() MiniPick.registry.marks() end, { desc = "Search marks" })
  vim.keymap.set("n", "<Leader>sp", function() MiniPick.registry.projects() end, { desc = "Search projects" })
  vim.keymap.set("n", "<Leader>s`", function() MiniPick.registry.registers() end, { desc = "Search register" })
end)

-- Visits

pack.now(function()
  local MiniVisits = require("mini.visits")
  local MiniExtra = require("mini.extra")

  MiniVisits.setup()

  local visit_paths = function(cwd, filter)
    local sort_latest = MiniVisits.gen_sort.default({ recency_weight = 1 })
    local name_filter = filter and string.format("'%s' ", filter) or ""
    local name = string.format("Visit %s(%s)", name_filter, cwd and "cwd" or "all")
    local local_opts = { cwd = cwd, filter = filter, sort = sort_latest }
    return MiniExtra.pickers.visit_paths(local_opts, { source = { name = name } })
  end

  local root_label = function()
    return vim.fs.relpath("~", util_root.find_root() or "")
  end

  -- stylua: ignore start
  vim.keymap.set("n", "<Leader>vn", function() MiniVisits.add_label() end, { desc = "Add label (new)" })
  vim.keymap.set("n", "<Leader>vn", function() MiniVisits.add_label() end, { desc = "Add label (new)" })
  vim.keymap.set("n", "<Leader>Vn", function() MiniVisits.remove_label() end, { desc = "Remove label (new)" })
  vim.keymap.set("n", "<Leader>vr", function() MiniVisits.add_label(root_label()) end, { desc = "Add label (root)" })
  vim.keymap.set("n", "<Leader>Vr", function() MiniVisits.remove_label(root_label()) end, { desc = "Remove label (root)" })
  vim.keymap.set("n", "<Leader>s?v", function() MiniPick.registry.visit_labels({ cwd = "all" }) end, { desc = "Search labels" })
  vim.keymap.set("n", "<Leader>sv", function() visit_paths(nil, root_label()) end, { desc = "Search visits (root)" })
  vim.keymap.set("n", "<Leader>sV", function() visit_paths() end, { desc = "Search visits (all)" })
end)
