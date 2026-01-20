local pack = require("util.pack")

pack.later(function()
  local MiniDiff = require("mini.diff")

  MiniDiff.setup({
    mappings = {
      textobject = "ih",
      goto_prev = "[h",
      goto_next = "]h",
    },
  })

  local hunk_action = function(mode)
    return function()
      return MiniDiff.operator(mode) .. MiniDiff.config.mappings.textobject
    end
  end

  vim.keymap.set("n", "gh", hunk_action("apply"), { expr = true, remap = true, desc = "Apply hunk" })
  vim.keymap.set("n", "gH", hunk_action("reset"), { expr = true, remap = true, desc = "Reset hunk" })
  -- stylua: ignore
  vim.keymap.set("n", "<Leader>go", function() MiniDiff.toggle_overlay() end, { desc = "Toggle overlay" })
end)
