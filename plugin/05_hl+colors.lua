local pack = require("util.pack")

pack.add({
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/nvim-mini/mini.hues" },
})

-- Highlights

pack.plug(function()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("custom_highlights", { clear = true }),
    desc = "Define permanent highlights",
    callback = function()
      -- Lsp notifications
      vim.api.nvim_set_hl(0, "LspProgress", { default = true, link = "Comment" })
      -- mini.hipatterns
      local perf_bg = vim.api.nvim_get_hl(0, { name = "Indentifier", link = false }).fg
      vim.api.nvim_set_hl(0, "HipatternsPerf", { bold = true, fg = "black", bg = perf_bg })
      -- mini.jump
      local jump_hl = { bold = true, fg = "violet" }
      vim.api.nvim_set_hl(0, "MiniJump", jump_hl)
      vim.api.nvim_set_hl(0, "MiniJump2dSpot", jump_hl)
      -- vim-matchup
      vim.api.nvim_set_hl(0, "MatchParen", {})
    end,
  })

  require("tokyonight").setup({
    on_highlights = function(hl, c)
      hl.LspProgress = { fg = c.comment }
    end,
  })
end)

-- Persistent colors

pack.plug(function()
  local colors_file = vim.fn.stdpath("state") .. "/colorscheme"

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("save_colors", { clear = true }),
    desc = "Save the current colorscheme to a file",
    callback = function()
      vim.fn.writefile({ vim.g.colors_name, vim.o.background }, colors_file)
    end,
  })

  local set_colorscheme = function(name, bg)
    return pcall(function()
      vim.o.background = bg
      vim.cmd.colorscheme(name)
    end)
  end

  local _, lines = pcall(vim.fn.readfile, colors_file)
  if not set_colorscheme(lines[1], lines[2]) then
    set_colorscheme("tokyonight", "dark")
  end
end)
