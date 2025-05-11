return {
  { 'windwp/nvim-ts-autotag', config = true }, -- Use treesitter to autoclose and autorename tags
  -- { 'windwp/nvim-autopairs', event = 'InsertEnter', config = true }, -- Autopair plugin

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    -- Load treesitter early when opening a file from the cmdline
    lazy = vim.fn.argc(-1) == 0,
    -- Drastically improves startup time by lazy loading syntax highlighting
    -- and other nvim-treesitter features
    event = 'VeryLazy',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    opts = {
      -- stylua: ignore
      ensure_installed = {
        'bash', 'c', 'lua', 'python', 'typescript', 'javascript', 'tsx',
        'html', 'markdown', 'markdown_inline', 'xml', 'vimdoc', 'jsdoc',
        'json', 'jsonc', 'toml', 'yaml',
        'diff', 'query', 'regex', 'printf',
      },
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
        enable = false,
        keymaps = {
          init_selection = '<CR>',
          node_incremental = '<CR>',
          node_decremental = '<BS>',
          scope_incremental = false,
        },
      },
    },
  },

  { -- Better/performant folding
    'kevinhwang91/nvim-ufo',
    event = 'VeryLazy',
    dependencies = 'kevinhwang91/promise-async',
    init = function()
      vim.o.foldenable = true
      -- Disable foldcolumn
      vim.o.foldcolumn = '0'
      -- Disable folding on startup
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      -- The first line of the fold will be syntax highlighted, rather than all be one color
      vim.o.foldtext = ''
      -- nvim-ufo only works if foldmethod=manual
      vim.o.foldmethod = 'manual'
      vim.o.foldexpr = nil
    end,
    config = function(_, opts)
      vim.schedule(function()
        require('ufo').setup(opts)
      end)
    end,
    opts = {
      provider_selector = function()
        return { 'treesitter', 'indent' }
      end,
      open_fold_hl_timeout = 0,
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (' 󰁂 %d '):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, 'MoreMsg' })
        return newVirtText
      end,
    },
    -- stylua: ignore
    keys = {
      { 'zR', function() require('ufo').openAllFolds() end },
      { 'zM', function() require('ufo').closeAllFolds() end },
      { 'zr', function() require('ufo').openFoldsExceptKinds() end },
      { 'zm', function() require('ufo').closeFoldsWith() end },
      {
        'K',
        function()
          local win = require('ufo').peekFoldedLinesUnderCursor()
          if not win then vim.lsp.buf.hover() end
        end,
      },
    },
  },

  { -- Treesitter based splitjoin
    'Wansmer/treesj',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { 'gs', function() require('treesj').toggle() end, desc = '[R]un [S]plitjoin' },
    },
    opts = {
      use_default_keymaps = false,
      max_join_length = 500,
      check_syntax_error = false,
    },
  },

  { -- Show your current context
    'nvim-treesitter/nvim-treesitter-context',
    event = 'VeryLazy',
    opts = {
      max_lines = 3,
      multiline_threshold = 1,
      trim_scope = 'inner',
    },
    -- stylua: ignore
    keys = {
      { '[g', function() require('treesitter-context').go_to_context(vim.v.count1) end, desc = '[G]oto treesitter context' },
    },
  },

  { -- Show rainbow delimiters
    'HiPhish/rainbow-delimiters.nvim',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<leader>tr', function() require('rainbow-delimiters').toggle(0) end, desc = '[T]oggle [r]ainbow delimiters' },
    },
    config = function()
      require('rainbow-delimiters.setup').setup {}
      vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        group = vim.api.nvim_create_augroup('rainbow_delimiters_off', {}),
        pattern = '*',
        callback = function()
          require('rainbow-delimiters').disable(0)
        end,
      })
    end,
  },

  { -- Interact code AST using queries
    'nvim-treesitter/nvim-treesitter-textobjects',
    event = 'VeryLazy',
    config = function()
      require('nvim-treesitter.configs').setup { ---@diagnostic disable-line: missing-fields
        textobjects = {
          select = {
            enable = true,
            -- Automatically jump forward to textobject, similar to targets.vim
            lookahead = true,
            keymaps = {
              ['ib'] = '@block.inner',
              ['ab'] = '@block.outer',
              ['ic'] = '@class.inner',
              ['ac'] = '@class.outer',
              ['aF'] = '@function.outer',
              ['iF'] = '@function.inner',
            },
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
              ['gj'] = { query = { '@function.outer', '@class.outer' }, desc = 'Goto next function or class' },
              [']f'] = { query = '@function.outer', desc = 'Goto next [f]unction' },
              [']c'] = { query = '@class.outer', desc = 'Goto next [c]lass' },
              [']a'] = { query = '@parameter.inner', desc = 'Goto next [a]rgument' },
              -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path. Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
              [']z'] = { query = '@fold', query_group = 'folds', desc = 'Goto next fold' },
            },
            goto_next_end = {
              ['gJ'] = { query = { '@function.outer', '@class.outer' }, desc = 'Goto next:end function or class' },
              [']F'] = { query = '@function.outer', desc = 'Goto next:end [F]unction' },
              [']C'] = { query = '@class.outer', desc = 'Goto next:end [C]lass' },
            },
            goto_previous_start = {
              ['gk'] = { query = { '@function.outer', '@class.outer' }, desc = 'Goto prev function or class' },
              ['[f'] = { query = '@function.outer', desc = 'Goto prev [f]unction' },
              ['[c'] = { query = '@class.outer', desc = 'Goto prev [c]lass' },
              ['[a'] = { query = '@parameter.inner', desc = 'Goto prev [a]rgument' },
              ['[z'] = { query = '@fold', query_group = 'folds', desc = 'Goto prev fold' },
            },
            goto_previous_end = {
              ['gK'] = { query = { '@function.outer', '@class.outer' }, desc = 'Goto prev:end function or class' },
              ['[F'] = { query = '@function.outer', desc = 'Goto prev:end [F]unction' },
              ['[C'] = { query = '@class.outer', desc = 'Goto prev:end [C]lass' },
            },
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

      -- local ts_repeat_move = require 'nvim-treesitter.textobjects.repeatable_move'
      --
      -- -- Repeat movement with ; and ,
      -- -- ensure ; goes forward and , goes backward regardless of the last direction
      -- vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move_next)
      -- vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_previous)
      --
      -- -- vim way: ; goes to the direction you were moving
      -- vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move)
      -- vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_opposite)
      --
      -- -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      -- vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f_expr, { expr = true })
      -- vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F_expr, { expr = true })
      -- vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t_expr, { expr = true })
      -- vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T_expr, { expr = true })
    end,
  },
}
