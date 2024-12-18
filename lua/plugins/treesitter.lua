-- Treesitter related stuff, nvim-treesitter and other plugins
--
return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- Drastically improves startup time by lazy loading syntax highlighting
    -- and other nvim-treesitter features
    event = 'VeryLazy',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      -- stylua: ignore
      ensure_installed = {
        'bash', 'c', 'lua', 'python', 'typescript', 'javascript', 'tsx',
        'html', 'markdown', 'markdown_inline', 'xml', 'vimdoc', 'jsdoc',
        'json', 'jsonc', 'toml', 'yaml',
        'diff', 'query', 'regex', 'printf',
      },

      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
      -- See `:help nvim-treesitter-incremental-selection-mod`
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<CR>',
          node_incremental = '<CR>',
          node_decremental = '<BS>',
          scope_incremental = false,
        },
      },
    },
    -- config = function(_, opts)
    --   require('nvim-treesitter.configs').setup(opts)
    -- end,
    init = function()
      -- Tree-sitter based folding (see `:help vim.treesitter.foldexpr())`
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      -- Turn off extra column to display information on folds
      vim.wo.foldcolumn = '0'
      -- The first line of the fold will be syntax highlighted, rather than all be one colour
      vim.wo.foldtext = ''
      -- Disable folding on startup
      vim.wo.foldlevel = 99
      -- This limits how deeply code gets folded. Helps to toggle larger chunks of nested code as they are treated as one fold
      -- vim.wo.foldnestmax = 5
    end,
  },

  { -- Show your current context
    'nvim-treesitter/nvim-treesitter-context',
    event = 'VeryLazy',
    opts = { multiline_threshold = 1 },
    keys = {
      {
        '[t',
        function()
          require('treesitter-context').go_to_context(vim.v.count1)
        end,
        desc = '[G]oto [T]op context line',
      },
    },
  },

  { -- Show rainbow delimiters
    'HiPhish/rainbow-delimiters.nvim',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>tr',
        function()
          require('rainbow-delimiters').toggle(vim.api.nvim_get_current_buf())
        end,
        desc = '[T]oggle [R]ainbow',
      },
    },
  },

  { -- Interact code AST using queries
    'nvim-treesitter/nvim-treesitter-textobjects',
    event = 'VeryLazy',
    config = function()
      require('nvim-treesitter.configs').setup { ---@diagnostic disable-line: missing-fields
        textobjects = {
          select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ia'] = '@parameter.inner',
              ['aa'] = '@parameter.outer',
              ['ib'] = '@block.inner',
              ['ab'] = '@block.outer',
              ['ic'] = '@class.inner',
              ['ac'] = '@class.outer',
              ['ii'] = '@conditional.inner',
              ['ai'] = '@conditional.outer',
              ['il'] = '@loop.inner',
              ['al'] = '@loop.outer',
              ['a/'] = '@comment.outer',
              ['i/'] = '@comment.inner',
            },
            -- You can choose the select mode (default is charwise 'v')
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * method: eg 'v' or 'o'
            -- and should return the mode ('v', 'V', or '<c-v>') or a table
            -- mapping query_strings to modes.
            -- selection_modes = {
            --   ['@parameter.outer'] = 'v', -- charwise
            --   ['@function.outer'] = 'V', -- linewise
            --   ['@class.outer'] = '<c-v>', -- blockwise
            -- },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`.
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * selection_mode: eg 'v'
            -- and should return true or false
            include_surrounding_whitespace = true,
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>a'] = { query = '@parameter.inner', desc = 'Swap next [a]rgument' },
            },
            swap_previous = {
              ['<leader>A'] = { query = '@parameter.inner', desc = 'Swap prev [A]rgument' },
            },
          },

          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']f'] = { query = '@function.outer', desc = 'Goto next [f]unction' },
              ['gj'] = { query = '@function.outer', desc = 'Goto next function' },
              [']c'] = { query = '@class.outer', desc = 'Goto next [c]lass' },
              [']b'] = { query = '@block.outer', desc = 'Goto next [b]lock' },
              [']a'] = { query = '@parameter.inner', desc = 'Goto next [a]rgument' },
              [']i'] = { query = '@conditional.inner', desc = 'Goto next [i]f conditional' },
              [']l'] = { query = '@loop.*', desc = 'Goto next [l]oop' },
              -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
              -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
              [']z'] = { query = '@fold', query_group = 'folds', desc = 'Goto next fold' },
            },
            goto_next_end = {
              [']F'] = { query = '@function.outer', desc = 'Goto next:end [F]unction' },
              ['gJ'] = { query = '@function.outer', desc = 'Goto next:end function' },
              [']C'] = { query = '@class.outer', desc = 'Goto next:end [C]lass' },
              [']B'] = { query = '@block.outer', desc = 'Goto next:end [B]lock' },
              [']A'] = { query = '@parameter.inner', desc = 'Goto next:end [A]rgument' },
              [']I'] = { query = '@conditional.inner', desc = 'Goto next:end [I]f conditional' },
              [']L'] = { query = '@loop.*', desc = 'Goto next:end [L]oop' },
            },
            goto_previous_start = {
              ['[f'] = { query = '@function.outer', desc = 'Goto prev [f]unction' },
              ['gk'] = { query = '@function.outer', desc = 'Goto prev function' },
              ['[c'] = { query = '@class.outer', desc = 'Goto prev [c]lass' },
              ['[b'] = { query = '@block.outer', desc = 'Goto prev [b]lock' },
              ['[a'] = { query = '@parameter.inner', desc = 'Goto prev [a]rgument' },
              ['[i'] = { query = '@conditional.inner', desc = 'Goto prev [i]f conditional' },
              ['[l'] = { query = '@loop.*', desc = 'Goto prev [l]oop' },
              ['[z'] = { query = '@fold', query_group = 'folds', desc = 'Goto prev fold' },
            },
            goto_previous_end = {
              ['[F'] = { query = '@function.outer', desc = 'Goto prev:end [F]unction' },
              ['gK'] = { query = '@function.outer', desc = 'Goto prev:end function' },
              ['[C'] = { query = '@class.outer', desc = 'Goto prev:end [C]lass' },
              ['[B'] = { query = '@block.outer', desc = 'Goto prev:end [B]lock' },
              ['[A'] = { query = '@parameter.inner', desc = 'Goto prev:end [A]rgument' },
              ['[I'] = { query = '@conditional.inner', desc = 'Goto prev:end [I]f conditional' },
              ['[L'] = { query = '@loop.*', desc = 'Goto prev:end [L]oop' },
            },
            -- Below will go to either the start or the end, whichever is closer.
            -- Use if you want more granular movements
            -- Make it even more gradual by adding multiple queries and regex.
            -- goto_next = {
            --   [']i'] = { query = '@conditional.outer', desc = 'Goto next [i]f conditional' },
            -- },
            -- goto_previous = {
            --   ['[i'] = { query = '@conditional.outer', desc = 'Goto prev [i]f conditional' },
            -- },
          },
          lsp_interop = {
            enable = true,
            border = 'none',
            floating_preview_opts = {},
            peek_definition_code = {
              ['<leader>df'] = { query = '@function.outer', desc = 'Peek [d]efintion for [f]unction' },
              ['<leader>dc'] = { query = '@class.outer', desc = 'Peek [d]efinition for [c]class' },
            },
          },
        },
      }

      local ts_repeat_move = require 'nvim-treesitter.textobjects.repeatable_move'

      -- Repeat movement with ; and ,
      -- ensure ; goes forward and , goes backward regardless of the last direction
      vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move_next)
      vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_previous)

      -- vim way: ; goes to the direction you were moving
      vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move)
      vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_opposite)

      -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T_expr, { expr = true })
    end,
  },
}
