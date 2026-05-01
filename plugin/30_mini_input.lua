local pack = require("util.pack")

pack.plug(function()
  local MiniInput = require("mini.input")

  local adjust_config = function(state, config)
    local input_width = vim.fn.strchars(state.input) + 1
    config.width = math.max(input_width, 35)
    return config
  end

  MiniInput.setup({
    handlers = {
      view = MiniInput.gen_view.floatwin({ adjust_config = adjust_config }),
    },
  })
end)
