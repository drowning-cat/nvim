local is_nvim_buf = function(buf)
  local path = vim.api.nvim_buf_get_name(buf or 0)
  local nvim_roots = {
    vim.fn.stdpath("config"),
    vim.fn.stdpath("data"),
    vim.fn.stdpath("state"),
    vim.fn.stdpath("cache"),
    vim.env.VIMRUNTIME,
  }
  return vim.iter(nvim_roots):any(function(root)
    return vim.fs.relpath(root, path) ~= nil
  end)
end

vim.b.minisurround_config = {
  custom_surroundings = {
    l = {
      output = function()
        if vim.g.vim_project or is_nvim_buf(0) then
          return { left = "vim.print({ ", right = " })" }
        else
          return { left = "print({ ", right = " })" }
        end
      end,
    },
  },
}

local mini_ai = require("shared.mini_ai")

vim.b.miniai_config = {
  custom_textobjects = {
    F = function(ai_type, id, opts)
      opts = vim.tbl_extend("force", opts or {}, { n_lines = 750 })
      local areg = mini_ai.find_capture("@function.outer", opts)
      if string.match(opts.search_method, "cover") then
        local lnum = vim.api.nvim_win_get_cursor(0)[1]
        local opts_cover = vim.tbl_extend("force", opts, { search_method = "cover" })
        local areg_cover = mini_ai.find_capture("@function.outer", opts_cover)
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
        local ireg = mini_ai.find_reg_pattern(areg, { "^.-%b()().*()end\n$" }, ai_type)
        if not ireg then
          opts.n_times = opts.n_times + 1
          return MiniAi.find_textobject(ai_type, id, opts)
        end
        if opts.operator_pending and vim.v.operator == "c" then
          return mini_ai.hooks.ins_newline(ireg)
        end
        return ireg
      end
    end,
  },
}
