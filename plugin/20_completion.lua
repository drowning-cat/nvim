local pack = require("util.pack")

pack.add({
  { src = "https://github.com/Saghen/blink.lib" }, -- 1
  {
    src = "https://github.com/Saghen/blink.cmp",
    data = {
      build = function()
        vim.cmd("BlinkCmp build")
      end,
    },
  },
})

pack.plug(function()
  require("blink.cmp").build()
  require("blink.cmp").setup({
    keymap = {
      ["<C-n>"] = { "show_and_insert", "select_next" },
      ["<C-p>"] = { "show_and_insert", "select_prev" },
      ["<C-j>"] = { "select_and_accept" },
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
