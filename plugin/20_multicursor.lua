local pack = require("util.pack")

pack.add({
  { src = "https://github.com/jake-stewart/multicursor.nvim" },
})

pack.plug(function()
  local mc = require("multicursor-nvim")
  mc.setup({ signs = false })
  vim.api.nvim_set_hl(0, "MultiCursorCursor", { link = "MultiCursorVisual" })
  local lineAddCursor = function(dir) ---@param dir -1|1 Direction
    local top, bot
    mc.action(function(ctx)
      top = ctx:mainCursor() == ctx:firstCursor()
      bot = ctx:mainCursor() == ctx:lastCursor()
    end)
    if top == bot or (top and dir == -1) or (bot and dir == 1) then
      mc.lineAddCursor(dir)
    else
      mc.deleteCursor()
    end
  end
  local enableOrClear = function()
    if mc.cursorsEnabled() then
      mc.clearCursors()
    else
      mc.enableCursors()
    end
  end
  local toggleCursor = function()
    if mc.hasCursors() and mc.cursorsEnabled() then
      mc.deleteCursor()
    else
      mc.toggleCursor()
    end
  end
  -- stylua: ignore start
  mc.addKeymapLayer(function(set)
    set("n", "<Esc>", function() enableOrClear() end)
    set({ "n", "x" }, "]x", function() mc.nextCursor() end, { desc = "Go next cursor" })
    set({ "n", "x" }, "[x", function() mc.prevCursor() end, { desc = "Go prev cursor" })
    set({ "n", "x" }, "<S-Right>", function() mc.nextCursor() end, { desc = "Go next cursor" })
    set({ "n", "x" }, "<S-Left>", function() mc.prevCursor() end, { desc = "Go prev cursor" })
    set("n", "<C-i>", function() mc.clearCursors() end)
    set("n", "<C-o>", function() mc.clearCursors() end)
    set("n", "<C-c>", function() mc.clearCursors() end)
  end)
  vim.keymap.set({ "n", "x" }, "<C-Space>", function() toggleCursor() end, { desc = "Toggle cursor" })
  vim.keymap.set({ "n", "x" }, "<C-S-j>", function() lineAddCursor(1) end, { desc = "Cursor below" })
  vim.keymap.set({ "n", "x" }, "<C-S-k>", function() lineAddCursor(-1) end, { desc = "Cursor above" })
  vim.keymap.set({ "n", "x" }, "<S-Down>", function() lineAddCursor(1) end, { desc = "Cursor below" })
  vim.keymap.set({ "n", "x" }, "<S-Up>", function() lineAddCursor(-1) end, { desc = "Cursor above" })
  vim.keymap.set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "Cursor next" })
  vim.keymap.set({ "n", "x" }, "<C-S-n>", function() mc.matchSkipCursor(1) end, { desc = "Cursor next" })
  vim.keymap.set({ "n", "x" }, "<C-p>", function() mc.matchAddCursor(-1) end, { desc = "Cursor prev" })
  vim.keymap.set({ "n", "x" }, "<C-S-p>", function() mc.matchSkipCursor(-1) end, { desc = "Cursor prev" })
  vim.keymap.set("n", "<C-LeftMouse>", function() mc.handleMouse() end, { desc = "Click cursor" })
  vim.keymap.set("n", "<C-LeftDrag>", function() mc.handleMouseDrag() end, { desc = "Drag cursor" })
  vim.keymap.set("n", "<C-LeftRelease>", function() mc.handleMouseRelease() end, { desc = "Drag cursor (end)" })
  vim.keymap.set("x", "I", function() mc.insertVisual() end)
  vim.keymap.set("x", "A", function() mc.appendVisual() end)
end)
