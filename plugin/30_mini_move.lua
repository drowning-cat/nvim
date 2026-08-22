local pack = require("util.pack")

pack.plug(function()
  local MiniMove = require("mini.move")

  MiniMove.setup({
    mappings = {
      up = "<C-k>",
      down = "<C-j>",
      left = "",
      right = "",
      line_left = "",
      line_down = "",
      line_up = "",
      line_right = "",
    },
  })
end)
