local pack = require("util.pack")

pack.add({
  { src = "https://github.com/supermaven-inc/supermaven-nvim" },
  { src = "https://github.com/nickjvandyke/opencode.nvim" },
})

pack.plug(function()
  local opencode = require("opencode")
  -- stylua: ignore start
  vim.keymap.set({ "n", "x" }, "<Leader>O", function() opencode.ask("@this ") end, { desc = "Ask OpenCode ..." })
  vim.keymap.set({ "n", "x" }, "go", function() return opencode.operator("@this ") end, { desc = "Append range to OpenCode", expr = true })
  vim.keymap.set("n", "goo", function() return opencode.operator("@this ") .. "_" end, { desc = "Append line to OpenCode", expr = true })
end)

pack.plug(function()
  require("supermaven-nvim").setup({
    keymaps = {
      accept_suggestion = "<Tab>",
      clear_suggestion = "<C-]>",
      accept_word = "<C-Tab>",
    },
  })
  local api = require("supermaven-nvim.api")
  api.stop()
  vim.keymap.set("n", "<Leader>m", function()
    if api.is_running() then
      api.stop()
      local ns = vim.api.nvim_create_namespace("supermaven")
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
      vim.notify("Stop supermaven", vim.log.levels.WARN)
    else
      api.start()
      vim.notify("Start supermaven", vim.log.levels.WARN)
    end
  end, { desc = "Toggle Supermaven" })
end)
