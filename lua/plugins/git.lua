return {
  'tpope/vim-fugitive', -- Vim integration with git, see `:help fugitive`

  { -- Open lazygit - a lightweight, terminal user interface for git
    'kdheepak/lazygit.nvim',
    lazy = true,
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    keys = {
      { '<leader>g', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
    },
  },

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      current_line_blame_opts = {
        delay = 0,
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, lhs, rhs, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, lhs, rhs, opts)
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

        map('n', '<leader>gs', gitsigns.stage_hunk, { desc = '[G]it [s]tage hunk' })
        map('n', '<leader>gr', gitsigns.reset_hunk, { desc = '[G]it [r]eset hunk' })
        -- stylua: ignore start
        map('v', '<leader>gs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = '[G]it [s]tage hunk' })
        map('v', '<leader>gr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = '[G]it [r]eset hunk' })
        -- stylua: ignore end
        map('n', '<leader>gu', gitsigns.undo_stage_hunk, { desc = '[G]it [u]ndo stage hunk' })
        map('n', '<leader>gS', gitsigns.stage_buffer, { desc = '[G]it [S]tage buffer' })
        map('n', '<leader>gR', gitsigns.reset_buffer, { desc = '[G]it [R]eset buffer' })
        map('n', '<leader>gp', gitsigns.preview_hunk, { desc = '[G]it [p]review hunk' })
        map('n', '<leader>gP', gitsigns.preview_hunk_inline, { desc = '[G]it [P]review hunk inline' })
        map('n', '<leader>gb', gitsigns.blame_line, { desc = '[G]it [b]lame line' })
        map('n', '<leader>gd', gitsigns.diffthis, { desc = '[G]it [d]iff against index' })
        -- stylua: ignore
        map('n', '<leader>gD', function() gitsigns.diffthis '@' end, { desc = '[G]it [D]iff against last commit' })
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git [b]lame line' })
        map('n', '<leader>tD', gitsigns.toggle_deleted, { desc = '[T]oggle git [D]eleted' })
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = '[G]it select hunk' })
      end,
    },
  },
}
