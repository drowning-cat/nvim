local ai_share = require("share.plugin.mini_ai")

vim.b.miniai_config = {
  custom_textobjects = {
    c = function(ai_type, _, opts)
      local reg = ai_share.find_pattern({ "```%w*().-()```" }, ai_type, opts)
      if not reg then
        return
      end
      if opts.operator_pending and vim.v.operator == "c" then
        return ai_share.hooks.ins_newline(reg)
      end
      return reg.to and reg or nil
    end,
  },
}
