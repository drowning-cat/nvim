return {
  { 'tpope/vim-fugitive', cmd = { 'Git', 'G' } },

  { -- A plugin to visualise and resolve conflicts in neovim
    'akinsho/git-conflict.nvim',
    event = 'VimEnter',
    opts = {
      default_mappings = {
        ours = 'co',
        theirs = 'ct',
        none = 'c0',
        both = 'cb',
        -- next = ']x',
        -- prev = '[x',
      },
    },
  },

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
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
            vim.cmd.normal { ']h', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Goto next [h]unk *change' })

        -- Navigation: next hunk
        map('n', '[h', function()
          if vim.wo.diff then
            vim.cmd.normal { '[h', bang = true }
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
        map('n', '<leader>gS', gitsigns.stage_buffer, { desc = '[G]it [S]tage buffer' })
        map('n', '<leader>gR', gitsigns.reset_buffer, { desc = '[G]it [R]eset buffer' })
        map('n', '<leader>gp', gitsigns.preview_hunk, { desc = '[G]it [p]review hunk' })
        map('n', '<leader>gP', gitsigns.preview_hunk_inline, { desc = '[G]it [P]review hunk inline' })
        map('n', '<leader>gb', gitsigns.blame_line, { desc = '[G]it [b]lame line' })
        map('n', '<leader>gd', gitsigns.diffthis, { desc = '[G]it [d]iff against index' })
        -- stylua: ignore
        map('n', '<leader>gD', function() gitsigns.diffthis '@' end, { desc = '[G]it [D]iff against last commit' })
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git [b]lame line' })
        map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = '[G]it select hunk' })
      end,
    },
  },
}
