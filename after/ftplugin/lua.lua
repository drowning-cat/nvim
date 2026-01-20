local ai_share = require("share.plugin.mini_ai")

vim.b.miniai_config = {
  custom_textobjects = {
    F = function(ai_type, id, opts)
      opts = vim.tbl_extend("force", opts or {}, { n_lines = 750 })
      local areg = ai_share.find_capture("@function.outer", opts)
      if opts.search_method:match("cover") then
        local lnum = vim.api.nvim_win_get_cursor(0)[1]
        local opts_cover = vim.tbl_extend("force", opts, { search_method = "cover" })
        local areg_cover = ai_share.find_capture("@function.outer", opts_cover)
        if areg_cover and areg_cover.from.line == lnum then
          areg = areg_cover
        end
      end
      if not areg then
        return
      end
      if ai_type == "a" then
        return areg
      end
      if ai_type == "i" then
        local ireg = ai_share.find_reg_pattern(areg, { "^.-%b()().*()end\n$" }, ai_type)
        if not ireg then
          opts.n_times = opts.n_times + 1
          return MiniAi.find_textobject(ai_type, id, opts)
        end
        if opts.operator_pending and vim.v.operator == "c" then
          return ai_share.hooks.ins_newline(ireg)
        end
        return ireg
      end
    end,
  },
}

if vim then
  vim.b.minisurround_config = {
    custom_surroundings = {
      l = { output = { left = "vim.print({ ", right = " })" } },
    },
  }
end
