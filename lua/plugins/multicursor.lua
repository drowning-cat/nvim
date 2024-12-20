--- @param direction -1|1
local lineAddCursor = function(direction)
  local mc = require 'multicursor-nvim'
  local doSkip = false
  mc.action(function(ctx)
    local main_cursor = ctx:mainCursor()
    local next_cursor = ctx:nextCursor(main_cursor:getPos(), { enabledCursors = true })
    local prev_cursor = ctx:prevCursor(main_cursor:getPos(), { enabledCursors = true })
    if direction == -1 then
      prev_cursor, next_cursor = next_cursor, prev_cursor
    end
    if next_cursor and not prev_cursor then
      local ny, nx = unpack(next_cursor:getPos())
      local my, mx = unpack(main_cursor:getPos())
      -- true if the next_cursor is exactly *one* line ahead of the main_cursor
      doSkip = my + direction == ny and mx == nx
    else
      doSkip = false
    end
  end)
  if doSkip then
    mc.skipCursor(direction == -1 and 'k' or 'j')
  else
    mc.lineAddCursor(direction)
  end
end

return {
  {
    'jake-stewart/multicursor.nvim',
    config = function()
      local mc = require 'multicursor-nvim'

      mc.setup()

      vim.api.nvim_set_hl(0, 'MultiCursorCursor', { link = 'Cursor' })
      vim.api.nvim_set_hl(0, 'MultiCursorVisual', { link = 'Visual' })
      vim.api.nvim_set_hl(0, 'MultiCursorSign', { link = 'SignColumn' })
      vim.api.nvim_set_hl(0, 'MultiCursorDisabledCursor', { link = 'Visual' })
      vim.api.nvim_set_hl(0, 'MultiCursorDisabledVisual', { link = 'Visual' })
      vim.api.nvim_set_hl(0, 'MultiCursorDisabledSign', { link = 'SignColumn' })

      --- @param mode string|string[]
      --- @param lhs string
      --- @param fn function
      --- @param opts? vim.keymap.set.Opts
      local map = function(mode, lhs, fn, opts)
        local blocked_filetypes = { ['neo-tree'] = true }
        vim.keymap.set(mode, lhs, function()
          if not blocked_filetypes[vim.bo.filetype] then
            fn()
          end
        end, opts)
      end

      map({ 'n' }, '<Esc>', function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        elseif mc.hasCursors() then
          mc.clearCursors()
        else
          vim.cmd [[ nohlsearch ]]
        end
      end, { desc = 'Enable or clear cursors' })

      -- stylua: ignore start
      map({'n','v'}, '<S-Up>', function() lineAddCursor(-1) end, { desc = 'Add a new cursor above' })
      map({'n','v'}, '<S-Down>', function() lineAddCursor(1) end, { desc = 'Add a new cursor below' })
      map({'n','v'}, '<S-Right>', function() mc.nextCursor() end, { desc = 'Jump to the next cursor' })
      map({'n','v'}, '<S-Left>', function() mc.prevCursor() end, { desc = 'Jump to the previous cursor' })
      map({'n','v'}, '<leader>n', function() mc.matchAddCursor(1) end, { desc = 'Add a [n]ew cursor below by matching' })
      map({'n','v'}, '<leader>N', function() mc.matchAddCursor(-1) end, { desc = 'Add a [N]ew cursor above by matching' })
      map({'n','v'}, '<leader>s', function() mc.matchSkipCursor(1) end, { desc = '[s]kip the cursor below by matching' })
      map({'n','v'}, '<leader>S', function() mc.matchSkipCursor(-1) end, { desc = '[S]kip the cursor above by matching' })
      map({'n','v'}, '<leader>x', function() mc.deleteCursor() end, { desc = 'Remove the main cursor' })
      map({'n','v'}, '<C-Space>', function() mc.toggleCursor() end, { desc = 'Add or remove the cursor' })
      map({'n'}, '<C-leftmouse>', function() mc.handleMouse() end, { desc = 'Add or remove the cursor' })
      map({'n'}, '<leader>gv', function() mc.restoreCursors() end, { desc = 'Bring back cursors if you accidentally clear them' })
      map({'v'}, 'M', function() mc.matchCursors() end, { desc = '[M]atch new cursors within visual selections by regex' })
      map({'v'}, '<leader>t', function() mc.transposeCursors(1) end, { desc = '[t]ranspose lines in the visual selection' })
      map({'v'}, '<leader>T', function() mc.transposeCursors(-1) end, { desc = '[T]ranspose lines in the visual selection backward' })
      map({'n','v'}, '<C-i>', function() mc.jumpForward() end)
      map({'n','v'}, '<C-o>', function() mc.jumpBackward() end)
      -- stylua: ignore end
    end,
  },
}
