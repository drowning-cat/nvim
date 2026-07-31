local to_install = vim.nonnil(vim.g.ts_install, {})

vim.g.ts_auto_install = vim.nonnil(vim.g.ts_auto_install, false)
vim.g.ts_auto_install_ignore = vim.nonnil(vim.g.ts_auto_install_ignore, {})

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

pack.plug(function()
  vim.treesitter.language.register("tsx", "typescriptreact")

  local ts = require("nvim-treesitter")
  ts.install(to_install)

  local attach = function(buf, lang)
    vim.treesitter.start(buf, lang)
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      vim.wo[win][0].foldmethod = "expr"
      vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
  end
  local ts_supported = ts.get_available()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    group = vim.api.nvim_create_augroup("ts_setup", { clear = true }),
    desc = "Attach treesitter to a buffer, install its parser if missing",
    callback = function(e)
      local ft, buf = e.match, e.buf
      local lang = vim.treesitter.language.get_lang(ft)
      if not lang then
        return
      end
      if vim.tbl_contains(ts.get_installed("parsers"), lang) then
        attach(buf, lang)
      elseif
        vim.g.ts_auto_install
        and not vim.tbl_contains(vim.g.ts_auto_install_ignore, lang)
        and vim.tbl_contains(ts_supported, lang)
      then
        ts.install(lang):await(function(_, ok)
          if ok and vim.api.nvim_buf_is_valid(buf) then
            attach(buf, lang)
          end
        end)
      end
    end,
  })
end)

pack.plug(function()
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

pack.plug(function()
  local ts_context = require("treesitter-context")
  ts_context.setup({ max_lines = 3 })
  -- stylua: ignore start
  vim.keymap.set("n", "[c", function() ts_context.go_to_context(vim.v.count1) end, { desc = "Jump context" })
end)

pack.plug(function()
  local treesj = require("treesj")
  treesj.setup({ use_default_keymaps = false })
  -- stylua: ignore start
  vim.keymap.set("n", "<Leader>S", function() treesj.toggle() end, { desc = "Tsj toggle" })
end)

pack.plug(function()
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
