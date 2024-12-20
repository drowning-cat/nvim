--- @param dir -1|1 Direction
local lineAddCursor = function(dir)
  local mc = require 'multicursor-nvim'
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

return {
  {
    'jake-stewart/multicursor.nvim',
    event = 'VeryLazy',
    init = function()
      vim.api.nvim_set_hl(0, 'MultiCursorCursor', { reverse = true })
      vim.api.nvim_set_hl(0, 'MultiCursorVisual', { link = 'Visual' })
      vim.api.nvim_set_hl(0, 'MultiCursorSign', { link = 'SignColumn' })
      vim.api.nvim_set_hl(0, 'MultiCursorMatchPreview', { link = 'Search' })
      vim.api.nvim_set_hl(0, 'MultiCursorDisabledCursor', { reverse = true })
      vim.api.nvim_set_hl(0, 'MultiCursorDisabledVisual', { link = 'Visual' })
      vim.api.nvim_set_hl(0, 'MultiCursorDisabledSign', { link = 'SignColumn' })
    end,
    config = function()
      local mc = require 'multicursor-nvim'

      mc.setup()

      -- stylua: ignore
      mc.addKeymapLayer(function(layerSet)
        layerSet({ 'n', 'x' }, '<S-x>', function() mc.deleteCursor() end, { desc = 'Delete cursor' })
        layerSet({ 'n', 'v' }, '<S-Right>', function() mc.nextCursor() end, { desc = 'Jump next cursor' })
        layerSet({ 'n', 'v' }, '<S-Left>', function() mc.prevCursor() end, { desc = 'Jump prev cursor' })
        layerSet({ 'n', 'x' }, '<C-s>', function() mc.matchSkipCursor(1) end, { desc = 'Match skip cursor below' })
        layerSet({ 'n', 'x' }, '<C-S-s>', function() mc.matchSkipCursor(-1) end, { desc = 'Match skip cursor above' })
        layerSet('n', '<C-i>', function() mc.clearCursors() end)
        layerSet('n', '<C-o>', function() mc.clearCursors() end)
        layerSet('n', '<Esc>', function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)

      -- stylua: ignore start
      vim.keymap.set({ 'n', 'v' }, '<S-Down>', function() lineAddCursor(1) end, { desc = 'Add cursor below' })
      vim.keymap.set({ 'n', 'v' }, '<S-Up>', function() lineAddCursor(-1) end, { desc = 'Add cursor above' })
      vim.keymap.set({ 'n', 'v' }, '<C-n>', function() mc.matchAddCursor(1) end, { desc = 'Match add cursor above' })
      vim.keymap.set({ 'n', 'v' }, '<C-S-n>', function() mc.matchAddCursor(-1) end, { desc = 'Match add cursor below' })
      vim.keymap.set({ 'n', 'v' }, '<C-Space>', function() mc.toggleCursor() end, { desc = 'Toggle cursor' })
      vim.keymap.set('n', '<leader>|', function() mc.alignCursors() end, { desc = 'Align cursors' })
      vim.keymap.set('n', '<C-LeftMouse>', mc.handleMouse)
      vim.keymap.set('n', '<C-LeftDrag>', mc.handleMouseDrag)
      vim.keymap.set('n', '<C-LeftRelease>', mc.handleMouseRelease)
      vim.keymap.set('n', 'ga', mc.addCursorOperator, { desc = 'Cursor operator' })
      vim.keymap.set('x', 'M', mc.matchCursors, { desc = '[M]atch cursors by regex' })
      vim.keymap.set('x', 'S', mc.splitCursors, { desc = '[S]plit cursors by regex' })
      vim.keymap.set('x', 'I', mc.insertVisual, { desc = 'Insert visual' })
      vim.keymap.set('x', 'A', mc.appendVisual, { desc = 'Append visual' })
      vim.keymap.set('n', '<leader>gv', function() mc.restoreCursors() end, { desc = 'Restore cursors' })
    end,
  },
}
