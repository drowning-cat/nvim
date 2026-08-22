local pack = require("util.pack")

pack.add({
  { src = "https://github.com/milanglacier/minuet-ai.nvim" },
  { src = "https://github.com/supermaven-inc/supermaven-nvim" },
  { src = "https://github.com/nickjvandyke/opencode.nvim" },
})

-- pack.plug(function()
--   local minuet = require("minuet")
--   minuet.setup({
--     provider = "openai_fim_compatible",
--     n_completions = 1,
--     context_window = 512,
--     provider_options = {
--       openai_fim_compatible = {
--         api_key = "TERM",
--         name = "Ollama",
--         end_point = "http://localhost:11434/v1/completions",
--         model = "qwen2.5-coder:0.5b",
--         optional = {
--           max_tokens = 1024,
--           top_p = 0.9,
--         },
--       },
--     },
--     virtualtext = {
--       auto_trigger_ft = { "*" },
--       show_on_completion_menu = true,
--       keymap = {
--         accept_line = "<Tab>",
--         accept = "<M-Tab>",
--       },
--     },
--   })
-- end)

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
      accept_suggestion = "<M-Tab>",
      clear_suggestion = "<C-]>",
      accept_word = "<C-Tab>",
    },
  })
  local preview = require("supermaven-nvim.completion_preview")
  vim.keymap.set("i", "<Tab>", function()
    local row = vim.pos.cursor().row
    local line_count = vim.api.nvim_buf_line_count(0)
    preview.on_accept_suggestion()
    local added = vim.api.nvim_buf_line_count(0) - line_count
    if added < 2 then
      return
    end
    vim.api.nvim_buf_set_lines(0, row + 2, row + 1 + added, false, {})
    vim.api.nvim_win_set_cursor(0, { row + 2, vim.v.maxcol })
  end, { desc = "Supermaven: accept line" })
  local api = require("supermaven-nvim.api")
  -- api.stop()
  vim.keymap.set("n", "<Leader>M", function()
    if api.is_running() then
      api.stop()
      local ns_maven = vim.api.nvim_create_namespace("config/supermaven")
      vim.api.nvim_buf_clear_namespace(0, ns_maven, 0, -1)
      vim.notify("Stop supermaven", vim.log.levels.WARN)
    else
      api.start()
      vim.notify("Start supermaven", vim.log.levels.WARN)
    end
  end, { desc = "Supermaven: toggle" })
end)
