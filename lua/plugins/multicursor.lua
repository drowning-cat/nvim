--- @param dir -1|1 Direction
local lineAddCursor = function(dir)
  local mc = require 'multicursor-nvim'
  local is_first, is_last
  mc.action(function(ctx)
    local active = { enabledCursors = true }
    is_first = ctx:mainCursor() == ctx:firstCursor(active)
    is_last = ctx:mainCursor() == ctx:lastCursor(active)
  end)
  if is_first ~= is_last and ((is_first and dir == 1) or (is_last and dir == -1)) then
    mc.deleteCursor()
  else
    mc.lineAddCursor(dir)
  end
end

return {
  {
    'jake-stewart/multicursor.nvim',
    event = 'VeryLazy',
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

      map('n', '<Esc>', function()
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
      map({'n','v'}, '<leader>x', function() mc.deleteCursor() end, { desc = 'Remove the main cursor' })
      map({'n','v'}, '<C-Space>', function() mc.toggleCursor() end, { desc = 'Add or remove the cursor' })
      map({'n'}, '<leader>|', function() mc.alignCursors() end, { desc = 'Align cursors' })
      map({'n'}, '<C-leftmouse>', function() mc.handleMouse() end, { desc = 'Add or remove the cursor' })
      map({'n'}, '<leader>gv', function() mc.restoreCursors() end, { desc = 'Bring back cursors if you accidentally clear them' })
      map({'v'}, 'M', function() mc.matchCursors() end, { desc = '[M]atch new cursors within visual selections by regex' })
      map({'n','v'}, '<C-i>', function() mc.jumpForward() end)
      map({'n','v'}, '<C-o>', function() mc.jumpBackward() end)
    end,
  },
}
