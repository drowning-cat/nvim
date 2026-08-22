local pack = require("util.pack")

pack.add({
  { src = "https://github.com/saghen/blink.lib" },
  { src = "https://github.com/saghen/blink.cmp" },
})

---@param dir "next"|"prev"
local select_choice = function(dir)
  return function()
    if not vim.snippet.active() then
      return false
    end
    local choices = vim.tbl_get(vim.snippet, "_session", "current_tabstop", "choices") or {}
    if vim.tbl_isempty(choices) then
      return false
    end
    if vim.fn.pumvisible() == 0 then
      pcall(vim.fn.complete, vim.fn.col("."), choices)
    else
      vim.api.nvim_feedkeys(vim.keycode(dir == "next" and "<C-n>" or "<C-p>"), "n", false)
    end
    return true
  end
end

pack.plug(function()
  local cmp = require("blink.cmp")
  cmp.build()
  cmp.setup({
    keymap = {
      ["<C-j>"] = { "select_and_accept" },
      ["<C-n>"] = { select_choice("next"), "show_and_insert", "select_next", "fallback" },
      ["<C-p>"] = { select_choice("prev"), "show_and_insert", "select_prev", "fallback" },
      ["<C-l>"] = { "snippet_forward", "fallback" },
      ["<C-h>"] = { "snippet_backward", "fallback" },
    },
    cmdline = {
      keymap = { ["<Right>"] = false, ["<Left>"] = false },
      completion = {
        menu = { auto_show = true },
        list = { selection = { preselect = false } },
      },
    },
  })
end)
