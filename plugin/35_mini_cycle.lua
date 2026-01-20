vim.g.cycle_config = vim.F.if_nil(vim.g.cycle_config, {})

local pack = require("util.pack")

pack.later(function()
  local MiniAi = _G.MiniAi ---@diagnostic disable-line
  if not MiniAi then
    vim.notify("[mini.cycle] Depends on `mini.ai`", vim.log.levels.WARN)
    return
  end

  local find_textobject = function(ai_type, spec, opts)
    opts = vim.tbl_extend("keep", opts or {}, { silent = true })
    local snap_config = vim.deepcopy(MiniAi.config)
    local tmp_id = "_"
    MiniAi.config = { custom_textobjects = { [tmp_id] = spec }, silent = opts.silent }
    local reg = MiniAi.find_textobject(ai_type, tmp_id, opts)
    MiniAi.config = snap_config
    return reg
  end

  local buf_get_text = function(reg)
    local from, to = reg.from, reg.to
    return vim.api.nvim_buf_get_text(0, from.line - 1, from.col - 1, to.line - 1, to.col, {})
  end

  local buf_set_text = function(reg, buf_text, follow)
    local from, to = reg.from, reg.to
    vim.api.nvim_buf_set_text(0, from.line - 1, from.col - 1, to.line - 1, to.col, buf_text)
    if follow then
      vim.api.nvim_win_set_cursor(0, { from.line, from.col - 1 })
    end
  end

  local function get_config()
    local config = {}
    vim.list_extend(config, vim.b.cycle_config or {})
    vim.list_extend(config, vim.g.cycle_config or {})
    for i, conf in ipairs(config) do
      conf = vim.tbl_extend("keep", conf, { words = {}, cycle = true, pat = "%f[%w]()%f[%W]" })
      conf._patterns = vim.tbl_map(function(word)
        local pat = conf.pat
        local word_pat, gc = pat:gsub("%(%)", word)
        return gc == 1 and word_pat or error(("[mini.cycle] Unable to substitute pattern: %s"):format(pat))
      end, conf.words)
      config[i] = conf
    end
    return config
  end

  local cycle_word = function()
    local config = get_config()
    local match_pattern = {}
    for _, conf in ipairs(config) do
      for i, word in ipairs(conf.words) do
        if word ~= "" then
          table.insert(match_pattern, conf._patterns[i])
        end
      end
    end
    local match_reg = find_textobject("a", { match_pattern }, {
      search_method = "cover_or_next",
      n_lines = 0,
      n_times = vim.v.count1,
    })
    if not match_reg then
      vim.notify("[mini.cycle] No matches found in the current line", vim.log.levels.WARN)
      return
    end
    local find_longest_cover = function(conf, ref_reg)
      local item_list = {}
      for i, word in ipairs(conf.words) do
        if word ~= "" then
          table.insert(item_list, { i = i, word = word, pat = conf._patterns[i] })
        end
      end
      table.sort(item_list, function(a, b)
        return #a.word >= #b.word
      end)
      for _, item in ipairs(item_list) do
        local cover_reg = find_textobject("a", { item.pat }, {
          search_method = "cover",
          n_lines = 0,
          n_times = 1,
          reference_region = { from = ref_reg },
        })
        if cover_reg then
          return cover_reg, item.i
        end
      end
    end
    local match_text = buf_get_text(match_reg)[1]
    for _, conf in ipairs(config) do
      if vim.list_contains(conf.words, match_text) then
        local cover_reg, i = find_longest_cover(conf, match_reg.from)
        if cover_reg then
          local next_index = conf.cycle and (i % #conf.words + 1) or math.min(i + 1, #conf.words)
          local next_word = conf.words[next_index]
          local cover_text = buf_get_text(cover_reg)[1]
          if next_word ~= cover_text then
            buf_set_text(cover_reg, { next_word }, true)
          end
          return
        end
      end
    end
  end

  -- stylua: ignore
  vim.keymap.set("n", "<Leader>c", function() cycle_word() end, { desc = "Cycle" })
end)
