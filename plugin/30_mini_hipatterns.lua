local pack = require("util.pack")

pack.plug(function()
  local MiniHipatterns = require("mini.hipatterns")

  -- See https://github.com/nvim-mini/mini.nvim/discussions/2031
  local hi_todo = function(words, hl_name)
    local pattern = vim
      .iter(words)
      :map(function(word)
        return {
          "%W() ?" .. word .. "%(.-%)[: ]()",
          "%W() ?" .. word .. "[: ]()",
        }
      end)
      :flatten()
      :totable()
    return {
      pattern = pattern,
      group = function(buf, _, data)
        local parser = vim.treesitter.get_parser(buf, nil, { error = false })
        if not parser then
          return
        end
        local range4 = {
          data.line - 1,
          data.from_col - 1,
          data.line - 1,
          data.to_col - 1,
        }
        parser:parse(range4)
        local node = parser:named_node_for_range(range4)
        if node and string.match(node:type(), "comment") then
          return hl_name
        end
      end,
    }
  end

  MiniHipatterns.setup({
    highlighters = {
      fix = hi_todo({ "FIX", "FIXME", "BUG" }, "MiniHipatternsFixme"),
      note = hi_todo({ "NOTE", "DEBUG" }, "MiniHipatternsNote"),
      todo = hi_todo({ "TODO", "FEAT" }, "MiniHipatternsTodo"),
      hack = hi_todo({ "WARN", "WARNING", "HACK" }, "MiniHipatternsHack"),
      perf = hi_todo({ "PERF" }, "HipatternsPerf"),
      hex_color = MiniHipatterns.gen_highlighter.hex_color(),
      hex_color_short = {
        -- https://www.lazyvim.org/extras/util/mini-hipatterns#minihipatterns
        pattern = "()#%x%x%x()%f[^%x%w]",
        group = function(_, _, data)
          local match = data.full_match
          local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
          local hex_color = "#" .. r .. r .. g .. g .. b .. b
          return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
        end,
      },
      hsl_color = {
        -- NOTE: Partial support for CSS hsl()
        pattern = "hsl%(%d+[, ] ?%d+%%?[, ] ?%d+%%?%)",
        group = function(_, m, _)
          -- https://www.w3.org/TR/css-color-3/#hsl-color
          local hsl_to_rgb = function(h, s, l)
            h, s, l = h % 360, s / 100, l / 100
            if h < 0 then
              h = h + 360
            end
            local f = function(n)
              local k = (n + h / 30) % 12
              local a = s * math.min(l, 1 - l)
              return l - a * math.max(-1, math.min(k - 3, 9 - k, 1))
            end
            return f(0) * 255, f(8) * 255, f(4) * 255
          end
          local h, s, l = string.match(m, "(%d+)[, ] ?(%d+)%%?[, ] ?(%d+)%%?")
          local r, g, b = hsl_to_rgb(h, s, l)
          local hex = string.format("#%02x%02x%02x", r, g, b)
          return MiniHipatterns.compute_hex_color_group(hex)
        end,
      },
    },
  })
end)
