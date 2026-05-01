local pack = require("util.pack")

pack.add({
  { src = "https://github.com/nickjvandyke/opencode.nvim" },
})

pack.plug(function()
  local opencode = require("opencode")
  -- stylua: ignore start
  vim.keymap.set({ "n", "x" }, "<Leader>o", function() opencode.ask("@this ") end, { desc = "Ask OpenCode ..." })
  vim.keymap.set({ "n", "x" }, "<Leader>O", function() opencode.select() end, { desc = "Select OpenCode ..." })
  vim.keymap.set({ "n", "x" }, "go", function() return opencode.operator("@this ") end, { desc = "Append range to OpenCode", expr = true })
  vim.keymap.set("n", "goo", function() return opencode.operator("@this ") .. "_" end, { desc = "Append line to OpenCode", expr = true })
  vim.keymap.set("n", "<C-S-u>", function() opencode.command("session.half.page.up") end, { desc = "Scroll OpenCode up" })
  vim.keymap.set("n", "<C-S-d>", function() opencode.command("session.half.page.down") end, { desc = "Scroll OpenCode down" })
end)
