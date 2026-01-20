local ts_install = vim.F.if_nil(vim.g.ts_install, {})

local pack = require("util.pack")

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("ts_update", { clear = true }),
  desc = "Update `nvim-treesitter`",
  callback = function(e)
    if e.data.kind == "update" and e.data.spec.name == "nvim-treesitter" then
      require("nvim-treesitter").update()
    end
  end,
})

pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
  { src = "https://github.com/Wansmer/treesj" },
  { src = "https://github.com/Wansmer/sibling-swap.nvim" },
  { src = "https://github.com/aaronik/treewalker.nvim" },
})

pack.now(function()
  vim.treesitter.language.register("tsx", "typescriptreact")

  local ts_filetypes = vim
    .iter(ts_install)
    :map(function(lang)
      return vim.treesitter.language.get_filetypes(lang)
    end)
    :flatten()
    :totable()

  require("nvim-treesitter").install(ts_install)

  vim.api.nvim_create_autocmd("FileType", {
    pattern = ts_filetypes,
    group = vim.api.nvim_create_augroup("ts_setup", { clear = true }),
    desc = "Setup treesitter for a buffer",
    callback = function(e)
      vim.treesitter.start(e.buf)
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      vim.wo[0][0].foldmethod = "expr"
      vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
  })

  local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
  vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
  vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)
  vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
  vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
  vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
  vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

  local ts_move = require("nvim-treesitter-textobjects.move")
  -- NOTE: See `mini.ai`
  local ts_move_captures = {
    ["A"] = { capture = { "@parameter.outer" } },
    ["F"] = { capture = { "@function.outer" } },
    ["C"] = { capture = { "@class.outer" } },
    ["I"] = { capture = { "conditional.outer", "@ternary.outer" }, desc = "@conditional, @ternary" },
    ["O"] = { capture = { "@block.outer", "@conditional.outer", "@loop.outer" }, desc = "@block, @conditional, @loop" },
  }
  for key, opts in pairs(ts_move_captures) do
    local capture, desc = opts.capture, opts.desc or opts.capture[1]
    -- stylua: ignore start
    vim.keymap.set({ "n", "x", "o" }, "]]" .. key, function() ts_move.goto_next_start(capture, "textobjects") end, { desc = desc })
    vim.keymap.set({ "n", "x", "o" }, "[[" .. key, function() ts_move.goto_previous_start(capture, "textobjects") end, { desc = desc })
    vim.keymap.set({ "n", "x", "o" }, "][" .. key, function() ts_move.goto_next_end(capture, "textobjects") end, { desc = desc })
    vim.keymap.set({ "n", "x", "o" }, "[]" .. key, function() ts_move.goto_previous_end(capture, "textobjects") end, { desc = desc })
  end
end)

pack.later(function()
  local ts_context = require("treesitter-context")
  ts_context.setup({ max_lines = 3 })
  -- stylua: ignore start
  vim.keymap.set("n", "[c", function() ts_context.go_to_context(vim.v.count1) end, { desc = "Jump context" })
end)

pack.later(function()
  local treesj = require("treesj")
  treesj.setup({ use_default_keymaps = false })
  -- stylua: ignore start
  vim.keymap.set("n", "<Leader>S", function() treesj.toggle() end, { desc = "Tsj toggle" })
end)

pack.later(function()
  local sw = require("sibling-swap")
  sw.setup({ use_default_keymaps = false })

  local tw = require("treewalker")
  tw.setup({ highlight = false })

  local swap = function(dir)
    assert(dir:match("left") or dir:match("right"))
    local cursor = vim.api.nvim_win_get_cursor(0)
    sw["swap_with_" .. dir]()
    if vim.deep_equal(cursor, vim.api.nvim_win_get_cursor(0)) then
      tw["swap_" .. dir]()
    end
  end

  -- stylua: ignore start
  vim.keymap.set({ "n", "v" }, "<Leader>a", function() swap("right") end, { desc = "Swap right" })
  vim.keymap.set({ "n", "v" }, "<Leader>A", function() swap("left") end, { desc = "Swap left" })
  vim.keymap.set({ "n", "v" }, "gk", function() tw.move_up() end, { desc = "Walk up" })
  vim.keymap.set({ "n", "v" }, "gj", function() tw.move_down() end, { desc = "Walk down" })
end)
