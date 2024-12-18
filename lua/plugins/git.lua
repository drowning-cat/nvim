-- Git integration with Neovim
--
return {
  { 'tpope/vim-fugitive', cmd = { 'Git', 'G' } },

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame_opts = {
        delay = 0,
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation: previous hunk
        map('n', ']h', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Goto next [h]unk *change' })

        -- Navigation: next hunk
        map('n', '[h', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Goto prev [h]unk *change' })

        -- stylua: ignore start
        map('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'Git [h]unk [s]tage' })
        map('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'Git [h]unk [r]eset' })
        -- stylua: ignore end
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Git [s]tage hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Git [r]eset hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Git [S]tage buffer' })
        map('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'Git [u]ndo stage hunk' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Git [R]eset buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Git [p]review hunk' })
        map('n', '<leader>hP', gitsigns.preview_hunk_inline, { desc = 'Git [P]review hunk inline' })
        map('n', '<leader>hb', gitsigns.blame_line, { desc = 'Git [b]lame line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'Git [d]iff against index' })
        -- stylua: ignore
        map('n', '<leader>hD', function() gitsigns.diffthis '@' end, { desc = 'Git [D]iff against last commit' })
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git [b]lame line' })
        map('n', '<leader>tD', gitsigns.toggle_deleted, { desc = '[T]oggle git [D]eleted' })
      end,
    },
  },
}
