local pack = require("util.pack")

pack.later(function()
  local MiniJump2d = require("mini.jump2d")

  MiniJump2d.setup({
    silent = true,
    mappings = {
      start_jumping = "sj",
    },
  })

  vim.keymap.set("n", "sw", function()
    local builtin = MiniJump2d.builtin_opts
    local opts = vim.tbl_deep_extend("force", builtin.word_start, { view = { n_steps_ahead = 2 } })
    MiniJump2d.start(opts)
  end, { desc = "Search word" })
end)
