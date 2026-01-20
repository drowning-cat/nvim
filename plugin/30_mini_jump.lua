local pack = require("util.pack")
local ts_repeat = require("util.ts_repeat")

pack.later(function()
  local MiniJump = require("mini.jump")

  MiniJump.setup({
    mappings = {
      repeat_jump = "",
    },
  })

  local minijump_jump = MiniJump.jump
  MiniJump.jump = function(target, backward, till, n_times)
    minijump_jump(target, backward, till, n_times)
    ts_repeat.save_last({
      forward = not vim.F.if_nil(backward, MiniJump.state.backward),
      func = function(isf)
        minijump_jump(target, not isf, till, n_times)
      end,
    })
  end

  local esc_key = vim.keycode("<Esc>")
  vim.on_key(function(_, key)
    if MiniJump.state.jumping and key == esc_key then
      MiniJump.stop_jumping()
    end
  end, vim.api.nvim_create_namespace("mini_jump_esc"))

  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = "no*:*",
    desc = "Stop `MiniJump` overlay after operator mode keymaps",
    callback = function()
      if MiniJump.state.jumping then
        MiniJump.stop_jumping()
      end
    end,
  })
end)
