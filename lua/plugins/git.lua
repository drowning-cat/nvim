local function get_default_branch_name()
  local res = vim.system({ 'git', 'rev-parse', '--verify', 'main' }, { capture_output = true }):wait()
  return res.code == 0 and 'main' or 'master'
end

return {
  { 'tpope/vim-fugitive', event = 'CmdlineEnter', cmd = { 'Git', 'G' } },

  {
    'sindrets/diffview.nvim',
    event = 'CmdlineEnter',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    init = function()
      vim.opt.fillchars:append { diff = ' ' }
    end,
    keys = {
      {
        '<leader>gdm',
        function()
          vim.cmd('DiffviewOpen ' .. get_default_branch_name())
        end,
        desc = '[G]it [d]iffview [m]ain',
      },
      {
        '<leader>gdM',
        function()
          vim.cmd('DiffviewOpen HEAD..origin/' .. get_default_branch_name())
        end,
        desc = '[G]it [d]iffview origin/[M]ain',
      },
      {
        '<leader>gdf',
        mode = { 'n', 'v' },
        function()
          local mode = vim.fn.mode()
          if mode == 'v' or mode == 'V' then
            vim.cmd [['<,'>DiffviewFileHistory --follow]]
          else
            vim.cmd [[DiffviewFileHistory --follow %]]
          end
        end,
        desc = '[G]it [d]iffview [f]ile history',
      },
      {
        '<leader>gdF',
        '<cmd>DiffviewFileHistory<cr>',
        desc = '[G]it [d]iffview [F]iles history',
      },
    },
  },

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
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git [b]lame line' })
        map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = '[G]it select hunk' })
      end,
    },
  },
}
