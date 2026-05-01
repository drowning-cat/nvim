local session_center = vim.nonnil(vim.g.session_center, false)

local pack = require("util.pack")

pack.plug(function()
  local MiniMisc = require("mini.misc")

  MiniMisc.setup_restore_cursor({ center = session_center })
end)
