local M = {}

local Range = require("vim.treesitter._range")

---@class HiExtmark
---@field row integer -- 0-based
---@field col integer -- 0-based
---@field extm vim.api.keyset.get_extmark

---@param query_range Range4? 0-based, end-exclusive
---@return HiExtmark[]
function M.get_ts_hls(source, lang, parse_range, query_range)
  parse_range = parse_range == nil and true or parse_range
  query_range = query_range
  local is_range4 = function(r)
    return r[1] and r[2] and r[3] and r[4]
  end
  if query_range and not is_range4(query_range) then
    error("`query_range` must be Range4|nil")
  end
  local parser, err ---@type vim.treesitter.LanguageTree?, string?
  if type(source) == "number" then
    parser, err = vim.treesitter.get_parser(source, lang)
  end
  if type(source) == "string" then
    parser, err = vim.treesitter.get_string_parser(source, lang)
  end
  if not parser then
    vim.notify(err or "Unable to get a parser", vim.log.levels.WARN)
    return {}
  end
  local ret = {}
  local prior_vals = {}
  parser:parse(parse_range)
  parser:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end
    local root_node = tstree:root()
    local root_range = { root_node:range() }
    local tsquery_range = query_range or root_range
    if not Range.intersection(root_range, tsquery_range) then
      return
    end
    local query = vim.treesitter.query.get(tree:lang(), "highlights")
    if not query then
      return
    end
    for id, node, metadata in
      query:iter_captures(
        root_node,
        source,
        tsquery_range[1],
        tsquery_range[3],
        { start_col = tsquery_range[2], end_col = tsquery_range[4] }
      )
    do
      local capture = query.captures[id]
      if capture ~= nil and capture ~= "spell" then
        local node_text = vim.treesitter.get_node_text(node, source, metadata[id])
        local text = vim.split(node_text, "\n")
        local range = { node:range() }
        local inter = Range.intersection(range, tsquery_range)
        if not inter then
          return
        end
        local col_start, col_end = inter[2], inter[4]
        local row_start, row_end = inter[1], col_end == 0 and inter[3] - 1 or inter[3]
        for row = row_start, row_end do
          local first, last = row == row_start, row == row_end
          local line = text[row - row_start + 1] or ""
          local col = first and col_start or 0
          local end_col = last and col_end or #line
          -- HACK: +1 `priority` for repeated columns
          local prior = tonumber(metadata.priority) or 100
          local prior_id = row .. ":" .. col
          prior = prior_vals[prior_id] and prior_vals[prior_id] + 1 or prior
          prior_vals[prior_id] = prior
          --
          ret[row] = ret[row] or {}
          table.insert(ret[row], {
            row = row,
            col = col,
            extm = {
              end_row = row,
              end_col = end_col,
              priority = prior,
              conceal = metadata.conceal,
              hl_group = "@" .. capture .. "." .. lang,
            },
          } --[[@as HiExtmark]])
        end
      end
    end
  end)
  local hls_flat = function(hls_tbl)
    local keys = vim.tbl_keys(hls_tbl)
    table.sort(keys)
    return vim.tbl_map(function(key)
      return hls_tbl[key]
    end, keys)
  end
  -- NOTE: Return highlights grouped by line
  ---@cast ret HiExtmark[][]
  ret = hls_flat(ret)
  return ret
end

function M.get_lang(ft)
  local lang = vim.treesitter.language.get_lang(ft or "")
  if not lang or not vim.treesitter.language.add(lang) then
    return nil
  end
  if not vim.api.nvim_get_runtime_file("queries/" .. lang .. "/highlights.scm", false) then
    return nil
  end
  return lang
end

function M.get_text_patched_hls(text, ft)
  text = type(text) == "table" and table.concat(text, "\n") or text
  local lang = M.get_lang(ft)
  if not lang then
    return {}
  end
  -- HACK: Complete keywords in order to get highlights
  if lang == "lua" then
    local prepend = { ["end"] = "do", ["until"] = "repeat" }
    local append = { ["do"] = "end", ["then"] = "end", ["repeat"] = "until" }
    local lines = vim.split(text, "\n")
    local first, last = lines[1], lines[#lines]
    local from, to = 0, #lines
    for _, word in ipairs(vim.split(first, "%s+")) do
      local add = prepend[word]
      if add then
        table.insert(lines, 1, add)
        from, to = from + 1, to + 1
      end
    end
    for _, word in ipairs(vim.split(last, "%s+")) do
      local add = append[word]
      if add then
        table.insert(lines, add)
      end
    end
    local patched_text = table.concat(lines, "\n")
    return M.get_ts_hls(patched_text, lang, true, { from, 0, to, 0 })
  end
  return M.get_ts_hls(text, lang)
end

function M.get_buf_hls(buf, with_extmarks, ln_range)
  if not vim.api.nvim_buf_is_valid(buf) then
    error(string.format("Invalid buffer: %s", buf))
  end
  ln_range[1] = ln_range[1] or 0
  ln_range[2] = ln_range[2] or vim.api.nvim_buf_line_count(buf)
  local lang = M.get_lang(vim.bo[buf].ft)
  if not lang then
    return {}
  end
  local range4 = { ln_range[1], 0, ln_range[2], 0 }
  local hls = M.get_ts_hls(buf, lang, range4, range4) or {}
  if with_extmarks then
    local start_pos, end_pos = { ln_range[1], 0 }, { ln_range[2] - 1, -1 }
    local extm_items = vim.api.nvim_buf_get_extmarks(buf, -1, start_pos, end_pos, { details = true })
    for _, extm_info in ipairs(extm_items) do
      local _, row, col, extm = unpack(extm_info)
      local ln = ln_range[1] - row + 1
      hls[ln] = hls[ln] or {}
      if extm then
        extm.sign_name = nil
        extm.sign_text = nil
        extm.ns_id = nil
        extm.end_row = nil
        if not vim.tbl_contains({ "eol", "overlay", "right_align", "inline" }, extm.virt_text_pos) then
          extm.virt_text = nil
          extm.virt_text_pos = nil
        end
        table.insert(hls[ln], { row = row, col = col, extm = extm })
      end
    end
  end
  return hls
end

return M
