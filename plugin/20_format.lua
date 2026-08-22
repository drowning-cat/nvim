local pack = require("util.pack")

vim.g.format_on_save = vim.nonnil(vim.g.format_on_save, false)
vim.g.formatters = vim.nonnil(vim.g.formatters, {})
vim.g.formatters_by_ft = vim.nonnil(vim.g.formatters_by_ft, {})

pack.plug(function()
  local async = vim.async

  ---@alias FormatRange [integer,integer] [line1, line2) 1-based

  ---@class FormatterContext
  ---@field buf integer
  ---@field buf_name string
  ---@field cwd string
  ---@field range FormatRange
  ---@field stdin string
  ---@field stdin_range FormatRange
  ---@field stdin_path string
  ---@field changedtick integer
  ---@field private tmp_paths table<string, true>
  ---@field private notify_fn fun(msg: string, level?: integer, opts?: table)
  --- +Methods

  ---@class FormatterTmpfile
  ---@field path string
  --- +Methods

  ---@class FormatterRunOpts : vim.SystemOpts
  ---@field cmd string[]
  ---@field stdin false|string
  ---@field exit_codes? integer[]

  ---@class FormatterEditOpts
  ---@field text string
  ---@field buf? integer
  ---@field in_range? FormatRange Replace range
  ---@field diff? "none"|"any"|"contain"|"overlap"
  ---       "none" - no diff; replace the entire `range`
  ---       "any" - apply all hunks within `range`
  ---       "contain" - apply hunks within `range` contained by `diff_range`
  ---       "overlap" - apply hunks within `range` overlapping `diff_range`
  ---@field diff_range? FormatRange
  ---@field diff_algorithm? "myers"|"minimal"|"patience"|"histogram"

  ---@class FormatterSpecStep : FormatterRunOpts
  ---@field cmd (string|[string?])[] `[string?]` is replaced with the temporary file path when `stdin=false`
  ---@field stdin? false|string `false` forces the use of a temporary file

  ---@class FormatterSpecOpts
  ---@field stdin_range? FormatRange
  ---@field [integer] FormatterSpecStep

  ---@class FormatterSpec : FormatterSpecOpts
  ---@field edit? FormatterEditOpts

  ---@alias Formatter fun(ctx: FormatterContext): FormatterSpec?

  ---@class FormatOpts
  ---@field buf? integer
  ---@field formatter? string|Formatter
  ---@field range? FormatRange
  ---@field async? boolean
  ---@field or_lsp? boolean
  ---@field silent? boolean
  ---@field timeout? integer

  ---@class FormatterContext
  local Context = {}
  Context.__index = Context

  ---@type FormatterContext[]
  Context.uncleaned = {}

  vim.api.nvim_create_autocmd("VimLeave", {
    group = vim.api.nvim_create_augroup("format/cleanup", { clear = true }),
    desc = "Cleanup formatting artifacts on exit",
    callback = function()
      for _, ctx in ipairs(Context.uncleaned) do
        ctx:cleanup()
      end
      Context.uncleaned = {}
    end,
  })

  ---@param lines string[]
  local lines_to_stdin = function(lines)
    return table.concat(lines, "\n") .. "\n"
  end

  ---@param buf integer
  ---@param range FormatRange
  ---@param notify_fn? fun()
  ---@return FormatterContext
  function Context.new(buf, range, notify_fn)
    notify_fn = notify_fn or vim.notify
    local buf_name = vim.api.nvim_buf_get_name(buf)
    local buf_dir = vim.fs.dirname(buf_name)
    local cwd = buf_dir and buf_dir ~= "." and buf_dir or vim.fn.getcwd()
    local stdin_range = { 1, vim.api.nvim_buf_line_count(buf) + 1 }
    local stdin_lines = vim.api.nvim_buf_get_lines(buf, stdin_range[1] - 1, stdin_range[2] - 1, true)
    local stdin_path = buf_name ~= "" and buf_name or vim.fs.joinpath(cwd, "[No name]")
    local ctx = setmetatable({
      buf = buf,
      buf_name = buf_name,
      cwd = cwd,
      range = range,
      stdin = lines_to_stdin(stdin_lines),
      stdin_range = stdin_range,
      stdin_path = stdin_path,
      changedtick = vim.b[buf].changedtick,
      tmp_paths = {},
      notify_fn = notify_fn,
    }, Context)
    table.insert(Context.uncleaned, ctx)
    return ctx
  end

  function Context:cleanup()
    if not vim.list_contains(Context.uncleaned, self) then
      return
    end
    for path in pairs(self.tmp_paths) do
      pcall(vim.fn.delete, path)
    end
    self.tmp_paths = {}
    Context.uncleaned = vim.tbl_filter(function(ctx)
      return ctx ~= self
    end, Context.uncleaned)
  end

  function Context:notify(msg, level, opts)
    self.notify_fn(msg, level, opts)
  end

  ---@param tmpname? string
  ---@return FormatterTmpfile
  function Context:tmpfile(tmpname)
    local path = vim.fs.normalize(tmpname or vim.fn.tmpname())
    if tmpname and not pcall(vim.fn.writefile, {}, path) then
      self:notify(string.format("Unable to write '%s'. Using system temp", path), vim.log.levels.WARN)
      path = vim.fn.tmpname()
    end
    local tmp_paths = self.tmp_paths
    tmp_paths[path] = true
    ---@class FormatterTmpfile
    local tmpfile = { path = path }
    ---@param content string
    function tmpfile:write(content)
      vim.fn.writefile(vim.split(content, "\n"), self.path)
    end
    function tmpfile:_read()
      return table.concat(vim.fn.readfile(self.path), "\n")
    end
    function tmpfile:delete()
      tmp_paths[self.path] = nil
      return pcall(vim.fn.delete, self.path)
    end
    function tmpfile:read_once()
      local content = self:_read()
      self:delete()
      return content
    end
    return tmpfile
  end

  ---@param cmd string
  function Context:has(cmd)
    return vim.fn.executable(cmd) == 1
  end

  ---@param cmd string[]
  ---@param sys_opts vim.SystemOpts
  function Context:_await_system(cmd, sys_opts)
    ---@type vim.SystemCompleted
    return async.await(function(done)
      local sys = vim.system(cmd, sys_opts, vim.schedule_wrap(done))
      ---@type vim.async.Closable
      return {
        is_closing = function()
          return sys:is_closing()
        end,
        close = function(_, cb)
          sys:kill("SIGTERM")
          if vim.is_callable(cb) then
            cb()
          end
        end,
      }
    end)
  end

  ---@async
  ---@param opts FormatterRunOpts
  ---@return string
  function Context:run(opts)
    local cmd = opts.cmd
    local exit_codes = opts.exit_codes or { 0 }
    local sys_opts = vim.tbl_extend("keep", opts, {
      cwd = self.cwd,
      text = true,
    })
    sys_opts.cmd = nil
    sys_opts.exit_codes = nil
    local out = self:_await_system(cmd, sys_opts)
    if out.signal ~= 0 then
      error(string.format("%s - terminated by signal %d", cmd[1], out.signal))
    end
    if not vim.list_contains(exit_codes, out.code) then
      error(string.format("%s (exit %d) - %s", cmd[1], out.code, out.stderr or ""), 0)
    end
    return out.stdout
  end

  ---@async
  ---@param opts FormatterSpecStep|FormatterSpecOpts
  ---@return FormatterEditOpts
  function Context:run_spec(opts)
    local buf = assert(self.buf)
    local spec = opts.cmd and { opts } or opts
    ---@type FormatterSpecOpts
    spec = vim.tbl_extend("keep", spec, {
      stdin_range = self.stdin_range,
    })
    local stdin_range = assert(spec.stdin_range)
    local stdin_lines = vim.api.nvim_buf_get_lines(buf, stdin_range[1] - 1, stdin_range[2] - 1, true)
    local input = lines_to_stdin(stdin_lines)
    local tmpfile ---@type FormatterTmpfile?
    local format_cmd = function(cmd)
      return vim.tbl_map(function(part)
        if type(part) == "table" then
          assert(tmpfile, "No tmpfile to resolve")
          return tmpfile.path
        end
        return part
      end, cmd)
    end
    for _, step in ipairs(spec) do
      if step.stdin == false then
        tmpfile = tmpfile or self:tmpfile()
        tmpfile:write(input)
        self:run(vim.tbl_extend("force", step, {
          cmd = format_cmd(step.cmd),
        }))
        input = tmpfile:_read()
      else
        input = self:run(vim.tbl_extend("keep", step, {
          stdin = input,
        }))
      end
    end
    if tmpfile then
      tmpfile:delete()
    end
    ---@type FormatterEditOpts
    return {
      text = input,
      in_range = stdin_range,
    }
  end

  ---@param start_line integer 0-based, inclusive
  ---@param end_line integer 0-based, exclusive
  ---@param repl string[]
  ---@return lsp.TextEdit
  local make_edit = function(start_line, end_line, repl)
    return {
      range = {
        start = { line = start_line, character = 0 },
        ["end"] = { line = end_line, character = 0 },
      },
      newText = not vim.tbl_isempty(repl) and lines_to_stdin(repl) or "",
    }
  end

  ---@param buf integer
  ---@param text_edits lsp.TextEdit[]
  local apply_edits = function(buf, text_edits)
    vim.lsp.util.apply_text_edits(text_edits, buf, "utf-8")
  end

  ---@param opts FormatterEditOpts
  function Context:edit(opts)
    vim.validate("opts.text", opts.text, "string")
    ---@type FormatterEditOpts
    opts = vim.tbl_extend("keep", opts or {}, {
      buf = self.buf,
      in_range = self.stdin_range,
      diff = "overlap",
      diff_range = nil,
      diff_algorithm = "myers",
    })
    local text = opts.text
    local buf = assert(opts.buf)
    local in_range = assert(opts.in_range)
    local text_lines = vim.islist(text) and text or vim.split(text, "\n") --[=[@as string[]]=]
    if opts.diff == "none" then
      local edit = make_edit(in_range[1] - 1, in_range[2] - 1, text_lines)
      apply_edits(buf, { edit })
      return
    end
    local buf_lines = vim.api.nvim_buf_get_lines(buf, in_range[1] - 1, in_range[2] - 1, true)
    local diff = vim.text.diff(lines_to_stdin(buf_lines), text, {
      result_type = "indices",
      algorithm = opts.diff_algorithm,
    })
    if not diff then
      return
    end
    ---@cast diff integer[][]
    local diff_range = opts.diff_range or in_range
    local text_edits = {}
    for _, hunk in ipairs(diff) do
      local old = { hunk[1], hunk[1] + hunk[2] }
      local new = { hunk[3], hunk[3] + hunk[4] }
      local old_buf = { in_range[1] + old[1] - 1, in_range[1] + old[2] - 1 }
      local add_edit = function()
        local repl = new[1] == new[2] and {} or vim.list_slice(text_lines, new[1], new[2] - 1)
        local offs = old[1] == old[2] and 0 or -1
        local edit = make_edit(old_buf[1] + offs, old_buf[2] + offs, repl)
        table.insert(text_edits, edit)
      end
      if opts.diff == "any" then
        add_edit()
      end
      if opts.diff == "contain" then
        if diff_range[1] <= old_buf[1] and diff_range[2] >= old_buf[2] then
          add_edit()
        end
      end
      if opts.diff == "overlap" then
        if diff_range[1] < old_buf[2] and old_buf[1] < diff_range[2] then
          add_edit()
        end
      end
    end
    apply_edits(buf, text_edits)
  end

  ---@param buf? integer
  local resolve_buf = function(buf)
    return (not buf or buf == 0) and vim.api.nvim_get_current_buf() or buf
  end

  ---@param buf integer
  ---@param range? FormatRange
  ---@return FormatRange
  local resolve_range = function(buf, range)
    range = range or {}
    local buf_end = vim.api.nvim_buf_line_count(buf) + 1
    if not vim.tbl_isempty(range) then
      return {
        range[1] or 1,
        range[2] and range[2] ~= -1 and range[2] or buf_end,
      }
    end
    local vis_mode = string.match(vim.api.nvim_get_mode().mode, "[vV\22]")
    if not vis_mode then
      return { 1, buf_end }
    end
    -- NOTE: A buffer has one selection range, even if displayed in multiple windows
    local reg = vim.api.nvim_buf_call(buf, function()
      return vim.fn.getregionpos(vim.fn.getpos("."), vim.fn.getpos("v"), {
        type = vis_mode,
        exclusive = false,
        eol = false,
      })
    end)
    return { reg[1][1][2], reg[#reg][1][2] + 1 }
  end

  ---@param opts FormatOpts
  ---@return boolean
  local format = function(opts)
    ---@type FormatOpts
    opts = vim.tbl_extend("keep", opts, {
      buf = 0,
      formatter = nil,
      range = nil,
      async = true,
      or_lsp = true,
      silent = false,
      timeout = 10000,
    })
    local buf = resolve_buf(opts.buf)
    local formatter = opts.formatter
    if type(formatter) == "string" then
      local name = formatter
      formatter = vim.tbl_get(vim.g.formatters or {}, formatter)
      assert(formatter, "Formatter not found: " .. name)
    else
      local ft = vim.bo[buf].ft
      formatter = vim.tbl_get(vim.g.formatters_by_ft or {}, ft)
      assert(formatter, "No formatter configured for filetype: " .. ft)
    end
    local range = resolve_range(buf, opts.range)
    local is_explicit_range = not vim.tbl_isempty(opts.range or {})
    local timeout_ms = assert(opts.timeout)
    if not vim.is_callable(formatter) then
      if not opts.or_lsp then
        return false
      end
      local lsp_range = nil
      if is_explicit_range then
        lsp_range = { start = { range[1] - 1, 0 }, ["end"] = { range[2] - 1, -1 } }
      end
      local vim_notify = vim.notify
      if opts.silent then
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function() end
      end
      vim.lsp.buf.format({
        bufnr = buf,
        range = lsp_range,
        async = opts.async,
        timeout_ms = timeout_ms,
      })
      vim.notify = vim_notify
      return true
    end
    ---@cast formatter Formatter
    local notify = function(msg, level, notif_opts)
      if not opts.silent then
        vim.notify(msg, level, notif_opts)
      end
    end
    local ctx = Context.new(buf, range, notify)
    local format_task = async.run(function()
      local format_runner = function()
        local spec = formatter(ctx)
        if not spec then
          return
        end
        local run_spec = vim.deepcopy(spec)
        run_spec.edit = nil
        local edit = ctx:run_spec(run_spec)
        edit = vim.tbl_extend("keep", spec.edit or {}, edit, {
          diff_range = range,
        })
        ctx:edit(edit)
      end
      return async.timeout(timeout_ms, async.run(format_runner))
    end)
    format_task:on_complete(function(err)
      vim.schedule(function()
        if err then
          notify("Format error: " .. err, vim.log.levels.ERROR)
        end
        ctx:cleanup()
      end)
    end)
    if not opts.async then
      return format_task:pwait() == true
    end
    return true
  end

  _G.Formatexpr = function()
    local range = { vim.v.lnum, vim.v.lnum + vim.v.count }
    local ok = format({ async = false, range = range })
    return ok and 0 or 1
  end
  vim.o.formatexpr = "v:lua.Formatexpr()"

  vim.keymap.set("n", "gqal", function()
    format({ async = true })
  end)

  vim.api.nvim_create_user_command("Format", function(args)
    format({
      formatter = args.fargs[1],
      range = args.range > 0 and { args.line1, args.line2 + 1 } or nil,
    })
  end, {
    nargs = "?",
    range = true,
    desc = "Format buffer",
    complete = function()
      return vim.tbl_keys(vim.g.formatters or {})
    end,
  })

  vim.cmd.cnoreabbrev("At", "AutoformatToggle")
  vim.api.nvim_create_user_command("AutoformatToggle", function()
    vim.g.format_on_save = not vim.g.format_on_save
    vim.notify(string.format("Autoformat toggle: %s", vim.g.format_on_save))
  end, {})

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("format_on_save", { clear = true }),
    desc = "Format on save",
    callback = function(e)
      local is_enabled = vim.nonnil(vim.b.format_on_save, vim.g.format_on_save, false)
      local ft = vim.bo[e.buf].ft
      if is_enabled and vim.g.formatters_by_ft[ft] then
        format({ async = false })
      end
    end,
  })
end)
