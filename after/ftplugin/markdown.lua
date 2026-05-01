local pack = require("util.pack")

-- mini.nvim

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

-- render-markdown.nvim

pack.add({
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
})

pack.plug(function()
  require("render-markdown").setup({
    checkbox = { enabled = false },
    code = { sign = false, width = "full" },
    heading = { icons = {} },
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    group = vim.api.nvim_create_augroup("render_md_keymaps", { clear = true }),
    desc = "Define `render-markdown` keymaps",
    callback = function()
      vim.keymap.set("n", "\\", "<Cmd>RenderMarkdown buf_toggle<Enter>", { desc = "Toggle md preview" })
    end,
  })
end)
