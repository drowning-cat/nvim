vim.g.lsp_enable = vim.nonnil(vim.g.lsp_enable, {})

local pack = require("util.pack")

pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
})

pack.plug(function()
  vim.lsp.enable(vim.g.lsp_enable or {})

  vim.diagnostic.config({
    virtual_text = true,
  })

  vim.keymap.set("n", "gK", function()
    local enable = not vim.diagnostic.config().virtual_text
    vim.diagnostic.config({
      virtual_text = enable,
      underline = enable,
    })
  end, { desc = "Toggle diagnostic display" })

  vim.keymap.set("n", "<Leader>ti", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, { desc = "Toggle inlay hint" })

  vim.keymap.set("n", "[e", function()
    vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
  end, { desc = "Goto previous error" })
  vim.keymap.set("n", "]e", function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
  end, { desc = "Goto next error" })

  vim.keymap.set({ "n", "x" }, "grc", function()
    vim.lsp.document_color.color_presentation()
  end, { desc = "Select color presentation" })

  local au_doc = vim.api.nvim_create_augroup("lsp/document_highlight", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorHold", "InsertLeave" }, {
    group = au_doc,
    desc = "Highlight references under the cursor",
    callback = function()
      local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/documentHighlight" })
      if vim.tbl_isempty(clients) then
        return
      end
      vim.lsp.buf.document_highlight()
    end,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
    group = au_doc,
    desc = "Clear highlighted references",
    callback = function()
      vim.lsp.buf.clear_references()
    end,
  })

  local au_inlay = vim.api.nvim_create_augroup("lsp/inlay_hint", { clear = true })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = au_inlay,
    desc = "Hide inlay hints when entering Insert mode",
    callback = function(e)
      local buf = e.buf
      vim.b[buf].inlay_hint = vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
      if vim.b[buf].inlay_hint then
        vim.lsp.inlay_hint.enable(false, { bufnr = buf })
      end
    end,
  })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = au_inlay,
    desc = "Show inlay hints after leaving Insert mode",
    callback = function(e)
      local buf = e.buf
      if vim.b[buf].inlay_hint then
        vim.lsp.inlay_hint.disable(false, { bufnr = e.buf })
      end
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_setup", { clear = true }),
    desc = "Configure a LSP server on attach",
    callback = function(e)
      local buf = e.buf
      local client = assert(vim.lsp.get_client_by_id(e.data.client_id))

      ---@param opts? vim.keymap.set.Opts
      local buf_map = function(modes, lhs, rhs, opts)
        opts = opts or {}
        opts.buf = buf
        vim.keymap.set(modes, lhs, rhs, opts)
      end

      if client:supports_method("textDocument/definition") then
        buf_map("n", "gd", function()
          vim.lsp.buf.definition()
        end, { desc = "Goto definition" })
        buf_map("n", "gD", function()
          local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
          vim.lsp.buf_request(0, "textDocument/definition", params, function(_, result)
            if not vim.tbl_isempty(result or {}) then
              local loc = vim.islist(result) and result[1] or result
              vim.lsp.util.preview_location(loc, { border = "rounded" })
            end
          end)
        end, { desc = "Peek definition" })
      end
    end,
  })
end)

-- LSP progress
-- See https://github.com/neovim/neovim/discussions/35349
pack.plug(function()
  local au = vim.api.nvim_create_augroup("lsp_progress", { clear = true })
  local ns = vim.api.nvim_create_namespace("lsp_progress")
  local timer = assert(vim.uv.new_timer())
  local buf = -1
  local win = -1
  local minmax = function(val, min, max)
    return math.floor(math.max(min, math.min(val, max)))
  end
  local text_overflow = function(line, max_width)
    if #line <= max_width then
      return line
    end
    local ell = "..."
    local cut = max_width - vim.fn.strwidth(ell)
    if cut <= 0 then
      return ell .. line
    end
    return line:sub(1, cut) .. ell
  end
  local lsp_notify = function(lines, hl, keep_ms)
    hl = hl or "Comment"
    keep_ms = keep_ms or nil
    if vim.tbl_isempty(lines) then
      return
    end
    local vpad, hpad = 0, 0
    local min_width, min_height = 1, 1
    local max_width, max_height = vim.o.columns / 3, vim.o.lines - 5
    local text_width = vim.iter(lines):fold(1, function(max, val)
      return math.max(max, #val)
    end)
    local width = math.floor(minmax(text_width, min_width, max_width))
    local height = math.floor(minmax(#lines, min_height, max_height))
    local win_config = { ---@type vim.api.keyset.win_config
      relative = "editor",
      anchor = "SE",
      row = vim.o.lines - 2,
      col = vim.o.columns,
      width = width + hpad * 2,
      height = height + vpad * 2,
      zindex = 100,
      style = "minimal",
      border = vim.o.winborder ~= "" and vim.o.winborder or "single",
      focusable = false,
      noautocmd = true,
    }
    if not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].ft = "lsp_progress"
    end
    if not vim.api.nvim_win_is_valid(win) then
      win = vim.api.nvim_open_win(buf, false, win_config)
      vim.wo[win].eventignorewin = "WinClosed"
      vim.wo[win].winhighlight = "Search:None,CurSearch:None"
    else
      vim.api.nvim_win_set_config(win, win_config)
    end
    local buf_lines = lines
    local cut_edge = vim.api.nvim_win_get_width(win) - hpad * 2
    for i, line in ipairs(buf_lines) do
      buf_lines[i] = text_overflow(line, cut_edge)
    end
    local padded = {}
    local hp = string.rep(" ", hpad)
    local vline = string.rep(" ", width + hpad * 2)
    local vp = vim.fn["repeat"]({ vline }, vpad)
    vim.list_extend(padded, vp)
    for _, line in ipairs(lines) do
      table.insert(padded, hp .. line .. hp)
    end
    vim.list_extend(padded, vp)
    buf_lines = padded
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
    vim.hl.range(buf, ns, hl, { 0, 0 }, { #buf_lines, -1 })
    if keep_ms and keep_ms > 0 then
      timer:stop()
      timer:start(keep_ms, 200, function()
        vim.schedule(function()
          if not vim.api.nvim_win_is_valid(win) or pcall(vim.api.nvim_win_close, win, true) then
            timer:stop()
          end
        end)
      end)
    end
  end
  vim.api.nvim_create_autocmd("LspProgress", {
    group = au,
    desc = "Show LSP progress status",
    callback = function(e)
      local msg = string.gsub(vim.lsp.status(), "^%s*%d+%%: ", "")
      local msg_lines = vim.split(msg, ", ")
      local kind = e.data.params.value.kind
      local hl_group = kind == "end" and "Special" or "LspProgress"
      -- NOTE: An error might be caused by the lock state, e.g. by `vim.fn.getcharstr`
      pcall(lsp_notify, msg_lines, hl_group, 1500)
    end,
  })
end)

-- Undim hovered diagnostic
-- See https://github.com/neovim/neovim/discussions/32513)
pack.plug(function()
  local underline_show = assert(vim.diagnostic.handlers.underline.show)
  local underline_hide = vim.diagnostic.handlers.underline.hide
  vim.diagnostic.handlers.underline = {
    show = function(ns, buf, diagnostics, opts)
      local show_diagnostics = {}
      local mode = vim.api.nvim_get_mode().mode
      if mode == "n" then
        local cursor = vim.api.nvim_win_get_cursor(0)
        local lnum, col = cursor[1] - 1, cursor[2]
        show_diagnostics = vim.tbl_filter(function(d) ---@param d vim.Diagnostic
          return not (
            d._tags
            and (d._tags.unnecessary or d._tags.deprecated)
            and lnum >= d.lnum
            and (lnum < d.end_lnum or (lnum == d.end_lnum and col < d.end_col))
          )
        end, diagnostics)
      end
      underline_show(ns, buf, show_diagnostics, opts)
    end,
    hide = underline_hide,
  }
  vim.api.nvim_create_autocmd({ "CursorHold", "ModeChanged" }, {
    group = vim.api.nvim_create_augroup("undim_underline", { clear = true }),
    desc = "Redraw `underline` diagnostics for cursor-aware filtering",
    callback = function(e)
      -- HACK: Avoid expensive `vim.diagnostic.show()` by calling the handlers directly
      local buf = e.buf
      for _, ns in ipairs(vim.diagnostic._store.get_buf_namespaces(buf)) do
        local is_diagnostics = vim.diagnostic.is_enabled({ bufnr = buf, ns = ns })
        if is_diagnostics then
          local opts = vim.diagnostic._config.get_resolved_options(nil, ns, buf)
          if opts.underline then
            local diagnostics = vim.diagnostic.get(buf, { namespace = ns, severity = opts.underline.severity })
            vim.diagnostic.handlers.underline.hide(ns, buf)
            vim.diagnostic.handlers.underline.show(ns, buf, diagnostics, opts)
          end
        end
      end
    end,
  })
end)

-- Lightbulb
-- See https://github.com/neovim/neovim/discussions/41197
pack.plug(function()
  local au = vim.api.nvim_create_augroup("lightbulb", { clear = true })
  local ns = vim.api.nvim_create_namespace("lightbulb")
  ---@param range vim.Range
  ---@param on_done fun(has_actions: boolean, results: table)
  local buf_request_code_actions = function(range, on_done)
    local buf = range.buf
    local overlaps_range = function(diagn) ---@param diagn vim.Diagnostic
      local diagn_range = vim.range(buf, diagn.lnum, diagn.col, diagn.end_lnum, diagn.end_col)
      return range:intersect(diagn_range) ~= nil
    end
    local diagnostics = vim.tbl_filter(overlaps_range, vim.diagnostic.get(buf))
    local lsp_diagnostics = vim.lsp.diagnostic.from(diagnostics)
    return vim.lsp.buf_request_all(buf, "textDocument/codeAction", function(client)
      return { ---@type lsp.CodeActionParams
        textDocument = vim.lsp.util.make_text_document_params(buf),
        range = range:to_lsp(client.offset_encoding),
        context = {
          diagnostics = lsp_diagnostics,
          triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic,
        },
      }
    end, function(results)
      local has_actions = vim.iter(vim.tbl_values(results)):any(function(res)
        return not vim.tbl_isempty(res.result or {})
      end)
      on_done(has_actions, results)
    end)
  end
  ---@return vim.Range
  local get_cursor_range = function(win)
    return vim.api.nvim_win_call(win, function()
      local vis = string.match(vim.api.nvim_get_mode().mode, "[Vv\22]")
      local _, crow, ccol = unpack(vim.fn.getpos("."))
      local _, vrow, vcol = unpack(vim.fn.getpos("v"))
      if vis == "V" then
        vcol = #vim.api.nvim_buf_get_lines(0, vrow - 1, vrow, true)[1]
      end
      local pos1 = vim.pos(0, vrow - 1, vcol - 1)
      local pos2 = vim.pos(0, crow - 1, ccol - 1)
      if pos2 < pos1 then
        pos1, pos2 = pos2, pos1
      end
      if vis then
        pos2[2] = pos2[2] + 1
      end
      return vim.range(pos1, pos2)
    end)
  end
  local cancel_pending = function(buf)
    buf = buf or 0
    local cancel = vim.b[buf]._lightbulb_cancel
    vim.b[buf]._lightbulb_cancel = nil
    if vim.is_callable(cancel) then
      pcall(cancel)
    end
  end
  local buf_show_at_cursor = function()
    local range = get_cursor_range(0)
    local buf = range.buf
    cancel_pending(buf)
    vim.b[buf]._lightbulb_cancel = buf_request_code_actions(range, function(has_actions)
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      if has_actions then
        pcall(function()
          vim.api.nvim_buf_set_extmark(buf, ns, range.start_row, 0, {
            virt_text = { { " 💡 Press `gra` to select a code action", "NonText" } },
            virt_text_pos = "eol",
          })
        end)
      end
    end)
  end
  local buf_hide = function(buf)
    buf = buf or 0
    cancel_pending(buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  -- Public
  _G.Lightbulb = {}
  local _enabled = false
  Lightbulb.is_enabled = function()
    return _enabled
  end
  local autocmd = function(event, opts) ---@param opts? vim.api.keyset.create_autocmd
    opts = opts or {}
    for _, ev in ipairs(vim.islist(event) and event or { event }) do
      local name, pattern = unpack(vim.split(ev, ":", { trimempty = true }))
      local au_opts = vim.tbl_extend("keep", opts, { group = au, pattern = pattern })
      vim.api.nvim_create_autocmd(name, au_opts)
    end
  end
  local hold_timer = assert(vim.uv.new_timer())
  Lightbulb.enable = function(enable)
    enable = vim.nonnil(enable, true)
    _enabled = enable
    vim.api.nvim_clear_autocmds({ group = au })
    -- Disable
    if not enable then
      hold_timer:stop()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        buf_hide(buf)
      end
      return
    end
    -- Enable
    buf_hide()
    buf_show_at_cursor()
    autocmd("CursorMoved", {
      group = au,
      desc = "Trigger `CursorHoldV`, emulates `CursorHold` in Visual mode",
      callback = function()
        hold_timer:stop()
        if string.match(vim.api.nvim_get_mode().mode, "[vV\22]") then
          hold_timer:start(vim.o.updatetime, 0, function()
            vim.schedule(function()
              vim.api.nvim_exec_autocmds("User", { pattern = "CursorHoldV" })
            end)
          end)
        end
      end,
    })
    autocmd({ "CursorHold", "User:CursorHoldV", "InsertLeave" }, {
      group = au,
      desc = "Show the lightbulb when code actions are available",
      callback = function()
        if not vim.b.lsp_lightbulb_disable then
          buf_show_at_cursor()
        else
          buf_hide()
        end
      end,
    })
    autocmd({ "InsertEnter", "BufLeave" }, {
      group = au,
      desc = "Hide the code action lightbulb",
      callback = function()
        buf_hide()
      end,
    })
  end
  -- Setup
  vim.api.nvim_create_user_command("LightbulbToggle", function()
    local enable = not Lightbulb.is_enabled()
    Lightbulb.enable(enable)
    vim.notify("Lightbulb " .. (enable and "enabled" or "disabled"))
  end)
end)
