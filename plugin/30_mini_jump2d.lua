local pack = require("util.pack")

pack.later(function()
  local MiniJump2d = require("mini.jump2d")

  MiniJump2d.setup({
    mappings = {
      start_jumping = "sj",
    },
  })
end)
