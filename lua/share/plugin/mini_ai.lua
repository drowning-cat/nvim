local M = {}

_G.MiniAi = _G.MiniAi

local Range = require("vim.treesitter._range")

local DEFAULT_ID = "_"

-- Utils

function M.reg2range(reg)
  local start_row, start_col = reg.from.line - 1, reg.from.col - 1
  local end_row, end_col
  if reg.to then
    end_row, end_col = reg.to.line - 1, reg.to.col
  else
    end_row, end_col = start_row, start_col
  end
  local end_line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, true)[1]
  if end_col > #end_line then
    end_row, end_col = end_row + 1, 0
  end
  return { start_row, start_col, end_row, end_col }
end

function M.set_text(reg, buf_text)
  local range = M.reg2range(reg)
  vim.api.nvim_buf_set_text(0, range[1], range[2], range[3], range[4], buf_text)
end

function M.get_text(reg)
  local range = M.reg2range(reg)
  return vim.api.nvim_buf_get_text(0, range[1], range[2], range[3], range[4], {})
end

function M.cmp_pos(op, pos1, pos2)
  local cmp = pos1.line == pos2.line and pos1.col - pos2.col or pos1.line - pos2.line
  local ops = { ["<"] = cmp < 0, ["<="] = cmp <= 0, ["=="] = cmp == 0, [">="] = cmp >= 0, [">"] = cmp > 0 }
  if ops[op] == nil then
    error("Invalid operator: " .. tostring(op))
  end
  return ops[op]
end

local cursor2pos = function(cursor)
  return { line = cursor[1], col = cursor[2] + 1 }
end

local get_cursor_reg = function()
  local from = cursor2pos(vim.api.nvim_win_get_cursor(0))
  return { from = from, to = vim.deepcopy(from) }
end

function M.nearest_reg(reg1, reg2)
  local cursor_reg = get_cursor_reg()
  if not reg1 or not reg2 then
    return reg1 or reg2
  end
  local p, p1, p2 = cursor_reg.from, reg1.from, reg2.from
  local r1, c1 = math.abs(p1.line - p.line), math.abs(p1.col - p.col)
  local r2, c2 = math.abs(p2.line - p.line), math.abs(p2.col - p.col)
  if r1 == r2 then
    return c1 <= c2 and reg1 or reg2
  else
    return r1 < r2 and reg1 or reg2
  end
end

-- Hooks

M.hooks = {}

local get_indent = function(ln)
  local line = vim.api.nvim_buf_get_lines(0, ln - 1, ln, true)[1]
  return string.match(line, "^%s*")
end

local feedkeys = function(keys, mode, escape_ks)
  mode, escape_ks = mode or "n", vim.F.if_nil(escape_ks, false)
  vim.api.nvim_feedkeys(vim.keycode(keys), mode, escape_ks)
end

function M.hooks.ins_newline(reg)
  local guicursor = vim.o.guicursor
  vim.o.guicursor = "i:hor50"
  vim.schedule(function()
    pcall(function()
      M.set_text(reg, { "", "", get_indent(reg.from.line) })
      vim.api.nvim_win_set_cursor(0, { reg.from.line + 1, 0 })
      if vim.bo.indentexpr ~= "" then
        feedkeys("<C-f>")
      end
    end)
    vim.o.guicursor = guicursor
  end)
end

-- Find

function M.find_textobject(spec, ai_type, tmp_id, opts)
  tmp_id = tmp_id or DEFAULT_ID
  opts = vim.tbl_extend("keep", opts or {}, { silent = true })
  local tmp_restore = MiniAi.config.custom_textobjects[tmp_id]
  local sil_restore = MiniAi.config.silent
  MiniAi.config.custom_textobjects[tmp_id] = spec
  MiniAi.config.silent = opts.silent
  local reg = MiniAi.find_textobject(ai_type, tmp_id, opts)
  MiniAi.config.custom_textobjects[tmp_id] = tmp_restore
  MiniAi.config.silent = sil_restore
  return reg
end

function M.find_pattern(pattern, ai_type, opts)
  local spec = pattern
  return M.find_textobject(spec, ai_type, nil, opts)
end

function M.find_capture(capture, opts)
  local spec = MiniAi.gen_spec.treesitter({ a = capture, i = "@" })
  return M.find_textobject(spec, "a", nil, opts)
end

local scratch_buf = -1
function M.find_text_pattern(text, pattern, ai_type, _opts)
  local buf_text = vim.islist(text) and text or vim.split(text, "\n")
  if not vim.api.nvim_buf_is_valid(scratch_buf) then
    scratch_buf = vim.api.nvim_create_buf(false, true)
  end
  local tmp_id = DEFAULT_ID
  local tmp_restore = MiniAi.config.custom_textobjects[tmp_id]
  MiniAi.config.custom_textobjects[tmp_id] = pattern
  vim.api.nvim_buf_set_lines(scratch_buf, 0, -1, true, buf_text)
  local reg = vim.api.nvim_buf_call(scratch_buf, function()
    _opts = vim.tbl_extend("keep", _opts or {}, {
      reference_region = { from = { line = 1, col = 1 } },
      n_lines = #buf_text,
      n_times = 1,
      search_method = "cover_or_next",
    })
    return MiniAi.find_textobject(ai_type, tmp_id, _opts)
  end)
  MiniAi.config.custom_textobjects[tmp_id] = tmp_restore
  return reg
end

local joinpos = function(abs_pos, rel_pos)
  return {
    line = abs_pos.line + rel_pos.line - 1,
    col = rel_pos.line == 1 and abs_pos.col + rel_pos.col - 1 or rel_pos.col,
  }
end

function M.find_reg_pattern(reg, pattern, ai_type, _opts)
  local buf_text = M.get_text(reg)
  local in_reg = M.find_text_pattern(buf_text, pattern, ai_type, _opts)
  if not in_reg then
    return
  end
  return {
    from = joinpos(reg.from, in_reg.from),
    to = in_reg.to and joinpos(reg.from, in_reg.to) or nil,
  }
end

-- Treesitter

function M.get_captures_at_reg(reg, group)
  group = group or "textobjects"
  local parser = vim.treesitter.get_parser()
  if not parser then
    return
  end
  local reg_range = M.reg2range(reg)
  local res = {}
  parser:for_each_tree(function(tree, ltree)
    local query = vim.treesitter.query.get(ltree:lang(), group)
    if not query then
      return
    end
    local iter_opts = { start_col = reg_range[2], end_col = reg_range[4] }
    for id, node, _ in query:iter_captures(tree:root(), 0, reg_range[1], reg_range[2], iter_opts) do
      local node_range = { node:range() }
      local name = query.captures[id]
      if Range.intersection(node_range, reg_range) then
        table.insert(res, { name = name, node = node })
      end
    end
  end)
  return res
end

function M.reg_in_capture(reg, caps)
  reg = reg or get_cursor_reg()
  caps = vim.islist(caps) and caps or { caps }
  return vim.iter(M.get_captures_at_reg(reg) or {}):any(function(cap)
    return vim.list_contains(caps, cap.name)
  end)
end

return M
