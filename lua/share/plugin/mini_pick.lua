local M = {}

_G.MiniPick = _G.MiniPick

local util_hi = require("util.highlight")

local pick_au = vim.api.nvim_create_augroup("minipick_show", { clear = true })
local pick_ns = vim.api.nvim_create_namespace("minipick_show")

vim.api.nvim_set_hl(0, "MiniPickMatchRanges", {
  bold = true,
  underdotted = true,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniPickStart",
  group = pick_au,
  desc = "Set `mini.pick` display options",
  callback = function()
    local state = MiniPick.get_picker_state()
    local win = state.windows.main
    local buf = state.buffers.main
    vim.bo[buf].tabstop = vim.go.tabstop
    vim.wo[win].listchars = vim.go.listchars
  end,
})

local pick_cache = {}

local pick_memo = function(id, func)
  if pick_cache[id] == nil then
    pick_cache[id] = { func() }
  end
  return unpack(pick_cache[id])
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniPickStop",
  group = pick_au,
  desc = "Clear `mini.pick` cache",
  callback = function()
    pick_cache = {}
  end,
})

-- Format

---@class ChunkExtm : vim.api.keyset.set_extmark
---@field row? integer
---@field col? integer

---@class Chunk
---@field text string
---@field extms ChunkExtm[]

--- ```lua
--- {
---   align = "left",
---   min = 0,
---   chunks = {
---     { text = "some word", extms = { { col = 6, end_col = 9, hl_group = "ErrorMsg" }, ... } },
---     { ... },
---   }
--- }
--- ```
---@class Slot
---@field align? "left"|"right"
---@field min? integer
---@field chunks Chunk[]

---@class FormatOpts
---@field sep? string
---@field tbl? boolean

---@param data Slot[][]
---@param opts? FormatOpts
local format = function(buf, data, opts)
  opts = vim.tbl_extend("keep", opts or {}, { sep = "│", tbl = true })
  -- Pre-process
  local slots = {} ---@type Slot[][]
  local slot_widths, slot_max = {}, 0
  for _, row_slots in ipairs(data) do
    local new_row = {}
    for _, slot in ipairs(row_slots) do
      if type(slot) == "table" then
        local slot_text, slot_chunk = "", {}
        for _, chunk in ipairs(slot.chunks or {}) do
          if type(chunk) == "table" and not vim.tbl_isempty(chunk) then
            local text = tostring(chunk.text or "")
            slot_text = slot_text .. text
            ---@type Chunk
            local new_chunk = { text = text, extms = vim.deepcopy(chunk.extms or {}) }
            table.insert(slot_chunk, new_chunk)
          end
        end
        local width = vim.fn.strdisplaywidth(slot_text)
        ---@type Slot
        local new_slot = vim.tbl_extend("force", { align = "left", min = 0 }, slot, {
          chunks = slot_chunk,
          _text = slot_text,
          _text_width = width,
        })
        table.insert(new_row, new_slot)
        local col = #new_row
        slot_widths[col] = math.max(slot_widths[col] or 0, new_slot.min, width)
      end
    end
    table.insert(slots, new_row)
    slot_max = math.max(slot_max, #new_row)
  end
  -- Pre-render
  local buf_lines, buf_extms = {}, {}
  for row, row_slots in ipairs(slots) do
    local line = ""
    for col, slot in ipairs(row_slots) do
      if col > 1 then
        line = line .. opts.sep
      end
      ---@diagnostic disable-next-line: undefined-field
      local text, text_width = slot._text, slot._text_width
      local width = math.max(slot.min --[[@as integer]], text_width)
      if opts.tbl and slot_max == #row_slots then
        width = slot_widths[col]
      end
      local pad = string.rep(" ", width - text_width)
      local left, right = "", ""
      if slot.align == "right" then
        left = pad
      end
      if slot.align == "left" and col < #row_slots then
        right = pad
      end
      local text_start = #line + #left
      local off = 0
      for _, chunk in ipairs(slot.chunks) do
        local shift = text_start + off
        for _, extm in ipairs(chunk.extms) do
          extm = vim.tbl_extend("force", extm, {
            row = row - 1,
            end_row = row - 1,
            col = (extm.col or 0) + shift,
            end_col = (extm.end_col and extm.end_col ~= -1) and (extm.end_col + shift) or (shift + #chunk.text),
          })
          table.insert(buf_extms, extm)
        end
        off = off + #chunk.text
      end
      line = line .. (left .. text .. right)
    end
    table.insert(buf_lines, line)
  end
  -- Render
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
  vim.api.nvim_buf_clear_namespace(buf, pick_ns, 0, -1)
  for _, extm in ipairs(buf_extms) do
    local row, col = extm.row or 0, extm.col or 0
    extm.row, extm.col = nil, nil
    vim.api.nvim_buf_set_extmark(buf, pick_ns, row, col, extm)
  end
end

local Slot = {}

function Slot.text(text, hl_group, opts)
  return vim.tbl_extend("force", opts or {}, {
    chunks = {
      { text = tostring(text or ""), extms = { { hl_group = hl_group } } },
    },
  } --[[@as Slot]])
end

function Slot.path(path)
  if #path > 30 then
    path = vim.fn.pathshorten(path)
  end
  return Slot.text(path)
end

function Slot.num(lnum)
  return Slot.text(lnum, nil, { align = "right", min = 2 })
end

local hl2extm = function(hl)
  return vim.tbl_extend("force", hl.extm, { col = hl.col, row = nil })
end

function Slot.buf_lnum(buf, lnum)
  return pick_memo(vim.inspect({ "buf_lnum", buf, lnum }), function()
    local text = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, true)[1]
    local extms = {}
    local row_hls = util_hi.get_buf_hls(buf, true, { lnum - 1, lnum })[1] or {}
    for _, hl in ipairs(row_hls) do
      if hl.extm.hl_group then
        table.insert(extms, hl2extm(hl))
      end
    end
    ---@type Slot
    return { chunks = { { text = text, extms = extms } } }
  end)
end

function Slot.code(code, path, ft)
  assert(not string.find(code, "\n"), "Code has new line")
  return pick_memo(vim.inspect({ "code", code, ft or path }), function()
    ft = ft or vim.filetype.match({ filename = path, contents = { code } })
    local extms = {}
    local row_hls = util_hi.get_text_patched_hls(code, ft)[1] or {}
    for _, hl in ipairs(row_hls) do
      table.insert(extms, hl2extm(hl))
    end
    ---@type Slot
    return { chunks = { { text = code, extms = extms } } }
  end)
end

M.gen_show = {}

local safe_show = function(show_fn)
  return function(buf, data, query, opts)
    xpcall(function()
      show_fn(buf, data, query, opts)
    end, function(err)
      vim.api.nvim_win_close(0, true)
      vim.api.nvim_echo({ { debug.traceback(err), "ErrorMsg" } }, true, {})
    end)
  end
end

---@param item_cb fun(item,i,buf,data,query): Slot[]
---@param opts? FormatOpts
local make_show = function(item_cb, opts)
  return safe_show(function(buf, data, query)
    local ret = {}
    for i, item in ipairs(data) do
      local row = item_cb(item, i, buf, data, query) or {}
      table.insert(ret, row)
    end
    format(buf, ret, opts)
  end)
end

function M.gen_show.buf_lines(local_opts)
  return make_show(function(item)
    local ret = {}
    if local_opts.scope == "all" then
      table.insert(ret, Slot.text(string.match(item.text, ".-%f[%z]")))
    end
    table.insert(ret, Slot.num(item.lnum))
    table.insert(ret, Slot.buf_lnum(item.bufnr, item.lnum))
    return ret
  end, { tbl = true })
end

function M.gen_show.git_hunks()
  local extract_code = function(item)
    for _, hunk_part in ipairs(item.hunk) do
      local sign, code = string.match(hunk_part, "^([+-])(.*)$")
      if sign and vim.trim(code) ~= "" then
        return sign, code
      end
    end
    return nil, item.hunk[2]
  end
  local code_slot = function(item)
    local sign, code = extract_code(item)
    local slot = vim.deepcopy(Slot.code(code, item.path))
    if sign then
      table.insert(slot, 1, { text = sign .. " " })
    end
    return slot
  end
  return make_show(function(item)
    local header = string.match(item.hunk[1], "@@ (.-) @@")
    return {
      Slot.path(item.path),
      Slot.text(" " .. header .. " "),
      code_slot(item),
    }
  end, { tbl = true })
end

local show_grep = function()
  return make_show(function(item)
    local path, lnum, col, code = unpack(vim.split(item, "%z"))
    return {
      Slot.path(path),
      Slot.num(lnum),
      Slot.num(col),
      Slot.code(code, path),
    }
  end)
end

M.gen_show.grep = show_grep
M.gen_show.grep_live = show_grep

function M.gen_show.hipatterns()
  return make_show(function(item)
    local path = vim.trim(string.match(item.text, ".-│(.-)│"))
    return {
      Slot.text(item.highlighter, item.hl_group),
      Slot.path(path),
      Slot.num(item.lnum),
      Slot.num(item.col),
      Slot.buf_lnum(item.bufnr, item.lnum),
    }
  end)
end

function M.gen_show.history()
  return make_show(function(item)
    if vim.startswith(item, ":") then
      return { Slot.code(item, nil, "vim") }
    else
      return { Slot.text(item) }
    end
  end)
end

function M.gen_show.lsp(local_opts)
  return make_show(function(item)
    if local_opts.scope == "document_symbol" then
      return { Slot.text(item.text, item.hl) }
    end
    local ret = {
      Slot.path(item.path),
      Slot.num(item.lnum),
      Slot.num(item.col),
    }
    local text = string.match(item.text, "^.-│.-│.-│(.*)")
    if local_opts.scope == "workspace_symbol_live" then
      local icon = string.match(item.text, "^%S+")
      table.insert(ret, Slot.text(" " .. icon .. text, item.hl))
    else
      table.insert(ret, Slot.code(text, item.path))
    end
    return ret
  end)
end

function M.gen_show.marks(local_opts)
  local_opts = vim.tbl_extend("keep", local_opts or {}, { scope = "buf" })
  local io_peek_line = function(path, lnum)
    if not vim.uv.fs_stat(path) then
      return
    end
    local ln = 0
    for line in io.lines(path) do
      ln = ln + 1
      if ln == lnum then
        return line
      end
    end
  end
  local code_slot = function(item)
    if item.bufnr then
      return Slot.buf_lnum(item.bufnr, item.lnum)
    end
    if item.path then
      local cache_id = vim.inspect({ "ln", item.path, item.lnum })
      local code = pick_memo(cache_id, function()
        return io_peek_line(item.path, item.lnum)
      end)
      return Slot.code(code or "", item.path)
    end
    return Slot.text()
  end
  local get_target_name = function()
    return pick_memo("buf_name", function()
      local target_win = MiniPick.get_picker_state().windows.target
      local target_buf = vim.api.nvim_win_get_buf(target_win)
      return vim.api.nvim_buf_get_name(target_buf)
    end)
  end
  return make_show(function(item)
    local ret = {}
    table.insert(ret, Slot.text(string.sub(item.text, 1, 1)))
    table.insert(ret, Slot.num(item.lnum))
    if local_opts.scope ~= "buf" then
      table.insert(ret, Slot.path(item.path or get_target_name()))
    end
    table.insert(ret, code_slot(item))
    return ret
  end, { tbl = true })
end

return M
