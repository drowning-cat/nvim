local session_center = vim.F.if_nil(vim.g.session_center, false)

local pack = require("util.pack")

pack.now(function()
  local MiniMisc = require("mini.misc")

  MiniMisc.setup_restore_cursor({ center = session_center })
end)
