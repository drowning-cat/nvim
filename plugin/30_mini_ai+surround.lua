local pack = require("util.pack")

_G.MiniIndentscope = _G.MiniIndentscope

local ai_share = require("share.plugin.mini_ai")
local ts_repeat = require("util.ts_repeat")

-- Ai

pack.later(function()
  local MiniAi = require("mini.ai")

  MiniAi.setup({
    mappings = {
      around_next = "aN",
      inside_next = "iN",
      around_last = "",
      inside_last = "",
      goto_left = "",
      goto_right = "",
    },
    custom_textobjects = {
      A = MiniAi.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
      C = MiniAi.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
      F = MiniAi.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
      I = MiniAi.gen_spec.treesitter({
        a = { "@conditional.outer", "@ternary.outer" },
        i = { "@conditional.inner", "@ternary.inner" },
      }),
      O = MiniAi.gen_spec.treesitter({
        a = { "@block.outer", "@loop.outer", "@conditional.outer" },
        i = { "@block.inner", "@loop.inner", "@conditional.inner" },
      }),
      a = MiniAi.gen_spec.argument({ separator = ",%s*" }),
      d = { "%d+" },
      e = function(ai_type, id, opts)
        local SEP = "_%-"
        if ai_type == "a" then
          -- stylua: ignore
          return {
            {
              -- pattern, [^_]pattern__
              "%f[%a"..SEP.."]%l+%d*["..SEP.."]*",
              "%f[%w"..SEP.."]%d+["..SEP.."]*",
              "%f[%u"..SEP.."]%u%f[%A]%d*["..SEP.."]*",
              "%f[%u"..SEP.."]%u%l+%d*["..SEP.."]*",
              "%f[%u"..SEP.."]%u%u+%d*["..SEP.."]*",
              --__pattern
              "%f["..SEP.."]["..SEP.."]+%l+%d*",
              "%f["..SEP.."]["..SEP.."]+%d+",
              "%f["..SEP.."]["..SEP.."]+%u%f[%A]%d*",
              "%f["..SEP.."]["..SEP.."]+%u%l+%d*",
              "%f["..SEP.."]["..SEP.."]+%u%u+%d*",
              --[_]pattern__[%s]
              "%f[^"..SEP.."]%l+%d*["..SEP.."]+%f[%s]",
              "%f[^"..SEP.."]%d+["..SEP.."]+%f[%s]",
              "%f[^"..SEP.."]%u%f[%A]%d*["..SEP.."]+%f[%s]",
              "%f[^"..SEP.."]%u%l+%d*["..SEP.."]+%f[%s]",
              "%f[^"..SEP.."]%u%u+%d*["..SEP.."]+%f[%s]",
            },
            "^().*()$",
          }
        end
        if ai_type == "i" then
          local reg = MiniAi.find_textobject("a", id, opts)
          if reg then
            local line = vim.fn.getline(reg.from.line)
            local _, s = line:find("^[" .. SEP .. "]*.", reg.from.col)
            local e = line:sub(1, reg.to.col):find(".[" .. SEP .. "]*$")
            return vim.tbl_deep_extend("force", reg, { from = { col = s }, to = { col = e } })
          end
        end
      end,
      f = function(ai_type, _, opts)
        local ts_prefix = ai_type == "a" and "outer" or "inner"
        local ts_reg = ai_share.find_capture("@call." .. ts_prefix)
        local function find_pattern(n_times)
          local find_opts = vim.tbl_extend("force", opts, { n_times = n_times })
          local spec = MiniAi.gen_spec.function_call()
          local reg = ai_share.find_textobject(spec, ai_type, nil, find_opts)
          if not reg then
            return
          end
          if ts_reg and ai_share.cmp_pos(">=", reg.from, ts_reg.from) then
            return
          end
          if ts_reg and not ai_share.reg_in_capture(reg, "comment.outer") then
            return find_pattern(n_times + 1)
          end
          return reg
        end
        return ai_share.nearest_reg(ts_reg, find_pattern(opts.n_times))
      end,
      g = function()
        local from = { line = 1, col = 1 }
        local to = {
          line = vim.fn.line("$"),
          col = math.max(vim.fn.getline("$"):len(), 1),
        }
        return { from = from, to = to }
      end,
      t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
    },
  })

  -- Move +repeat

  local miniai_move_cursor = MiniAi.move_cursor
  MiniAi.move_cursor = function(side, ai_type, id, opts)
    opts = vim.tbl_extend("keep", opts or {}, { n_times = vim.v.count1 })
    miniai_move_cursor(side, ai_type, id, opts)
    local search_method = opts.search_method or MiniAi.config.search_method
    local is_forward = not string.match(search_method, "prev")
    if not opts.no_repeat then
      ts_repeat.save_last({
        forward = is_forward,
        func = function(isf)
          local new_opts = vim.deepcopy(opts)
          local new_side = side
          if isf then
            new_opts.search_method = search_method:gsub("prev", "next")
          else
            new_opts.search_method = search_method:gsub("next", "prev")
          end
          new_side = new_opts.search_method:match("next") and "left" or "right"
          miniai_move_cursor(new_side, ai_type, id, new_opts)
        end,
      })
    end
  end

  -- NOTE: See `nvim-treesitter-textobjects`
  local move_opts = {
    a = { id = "a", ai_type = "i", desc = "argument" },
    e = { id = "e", ai_type = "i", desc = "subword" },
    f = { id = "f", ai_type = "a", desc = "call" },
    q = { id = "q", ai_type = "a", desc = "quote" },
    t = { id = "t", ai_type = "a", desc = "tag" },
  }

  for key, opts in pairs(move_opts) do
    local id, ai_type, desc = opts.id or key, opts.ai_type or "a", opts.desc
    -- stylua: ignore start
    vim.keymap.set({ "n", "x", "o" }, "]]" .. key, function() MiniAi.move_cursor("left", ai_type, id, { search_method = "next" }) end, { desc = desc })
    vim.keymap.set({ "n", "x", "o" }, "[[" .. key, function() MiniAi.move_cursor("left", ai_type, id, { search_method = "prev" }) end, { desc = desc })
    vim.keymap.set({ "n", "x", "o" }, "][" .. key, function() MiniAi.move_cursor("right", ai_type, id,{ search_method =  "next" }) end, { desc = desc })
    vim.keymap.set({ "n", "x", "o" }, "[]" .. key, function() MiniAi.move_cursor("right", ai_type, id,{ search_method =  "prev" }) end, { desc = desc })
  end

  local has_pos = function(reg, pos)
    local line, col = pos[1], pos[2]
    if reg.from.line == reg.to.line then
      return line == reg.from.line and col >= reg.from.col and col <= reg.to.col
    end
    return line >= reg.from.line and line <= reg.to.line
  end

  local go_edge = function(dir)
    local id = vim.fn.getcharstr()
    local is_forward = dir == "right"
    local jump = function(isf)
      local ai_type = (move_opts[id] or {}).ai_type or "a"
      local cover_reg = MiniAi.find_textobject(ai_type, id, { search_method = "cover", n_times = vim.v.count1 })
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line, col = cursor[1], cursor[2] + 1
      local pos = { line, col + (isf and 1 or -1) }
      if cover_reg and has_pos(cover_reg, pos) then
        local side = isf and "right" or "left"
        MiniAi.move_cursor(side, ai_type, id, { search_method = "cover", no_repeat = true })
      else
        local side = isf and "left" or "right"
        local search_method = isf and "next" or "prev"
        MiniAi.move_cursor(side, ai_type, id, { search_method = search_method, no_repeat = true })
      end
    end
    jump(is_forward)
    ts_repeat.save_last({ forward = is_forward, func = jump })
  end

  -- stylua: ignore start
  vim.keymap.set({ "n", "x", "o" }, "g]", function() go_edge("right") end, { desc = "Go edge right" })
  vim.keymap.set({ "n", "x", "o" }, "g[", function() go_edge("left") end, { desc = "Go edge left" })
  -- stylua: ignore end

  vim.keymap.set("i", "<M-w>", "<Esc>ciw", { remap = true, desc = "Delete word" })
  vim.keymap.set("i", "<M-e>", "<Esc>cie", { remap = true, desc = "Delete subword" })
  vim.keymap.set("n", "<M-e>", "<Esc>]]e", { remap = true, desc = "Next subword" })
  vim.keymap.set("n", "<M-E>", "<Esc>[[e", { remap = true, desc = "Previous subword" })
end)

-- Surround

pack.later(function()
  local MiniSurround = require("mini.surround")

  local surround_sel = function()
    local mark1 = vim.api.nvim_buf_get_mark(0, vim.v.operator == ":" and "<" or "[")
    local mark2 = vim.api.nvim_buf_get_mark(0, vim.v.operator == ":" and ">" or "]")
    local range = { mark1[1], mark1[2], mark2[1], mark2[2] }
    range[4] = math.min(range[4], #vim.fn.getline(range[3]) - 1)
    local text_lines = vim.api.nvim_buf_get_text(0, range[1] - 1, range[2], range[3] - 1, range[4] + 1, {})
    return text_lines, range
  end

  local ts_surround = function(...)
    return {
      input = MiniSurround.gen_spec.input.treesitter(...),
    }
  end

  local select_vis = function(line1, col1, line2, col2)
    local pos = function(line, col)
      return {
        line,
        col ~= -1 and col or #vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1],
      }
    end
    vim.api.nvim_win_set_cursor(0, pos(line1, col1))
    vim.cmd.norm("v")
    vim.api.nvim_win_set_cursor(0, pos(line2, col2))
  end

  MiniSurround.setup({
    mappings = {
      find = "",
      find_left = "",
      highlight = "",
      suffix_last = "",
      suffix_next = "n",
    },
    custom_surroundings = {
      F = ts_surround({ outer = "@function.outer", inner = "@function.inner" }),
      i = {
        input = function()
          local scope = MiniIndentscope and MiniIndentscope.get_scope() or nil
          if scope then
            local border_top, body_top = scope.border.top, scope.body.top
            local border_bot, body_bot = scope.border.bottom, scope.body.bottom
            local border_lines = {}
            vim.list_extend(border_lines, vim.api.nvim_buf_get_lines(0, border_top - 1, body_top - 1, true))
            vim.list_extend(border_lines, vim.api.nvim_buf_get_lines(0, body_bot, border_bot, true))
            vim.cmd("sil norm " .. string.rep("[i", vim.v.count - 1) .. "viiy']vaiopgv<")
            vim.fn.setreg(vim.v.register, table.concat(border_lines, "\n"), "l")
          end
        end,
      },
      l = nil, -- Reserved for `log`
      L = {
        output = function()
          if not vim.b.minisurround_config.custom_surroundings["l"] then
            return
          end
          local sel_lines, sel_range = surround_sel()
          local indent_str = string.match(vim.fn.getline(sel_range[1]), "^%s*")
          sel_lines[1] = string.gsub(sel_lines[1], "^%s*", indent_str)
          vim.api.nvim_buf_set_lines(0, sel_range[3], sel_range[3], true, sel_lines)
          select_vis(sel_range[3] + 1, #indent_str, sel_range[3] + #sel_lines, sel_range[4])
          vim.cmd.norm("sal")
        end,
      },
    },
  })
end)
