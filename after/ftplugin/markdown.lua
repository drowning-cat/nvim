local mini_ai = require("shared.mini_ai")

vim.b.miniai_config = {
  custom_textobjects = {
    c = function(ai_type, _, opts)
      local reg = mini_ai.find_pattern({ "```%w*().-()```" }, ai_type, opts)
      if not reg then
        return
      end
      if opts.operator_pending and vim.v.operator == "c" then
        return mini_ai.hooks.ins_newline(reg)
      end
      return reg.to and reg or nil
    end,
  },
}
