return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      local telescope = require 'telescope'
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'
      local themes = require 'telescope.themes'

      local accept_help = function()
        local entry = action_state.get_selected_entry()
        actions.select_default()
        vim.fn.histadd('cmd', 'h ' .. entry.display)
      end

      telescope.setup {
        defaults = {
          layout_config = {
            horizontal = {
              preview_width = 0.45,
            },
          },
          mappings = {
            i = {
              ['<C-CR>'] = 'to_fuzzy_refine',
              ['<C-j>'] = 'move_selection_next',
              ['<C-k>'] = 'move_selection_previous',
              ['<C-f>'] = function() end,
            },
            n = {
              ['V'] = 'select_vertical',
              ['H'] = 'select_horizontal',
            },
          },
        },
        pickers = {
          help_tags = {
            mappings = {
              i = {
                ['<CR>'] = accept_help,
                ['<C-y>'] = accept_help,
              },
              n = {
                ['<CR>'] = accept_help,
              },
            },
          },
        },
        extensions = {
          ['ui-select'] = {
            themes.get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(telescope.load_extension, 'fzf')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch [B]uffers' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader>sp', builtin.spell_suggest, { desc = '[S]earch S[p]elling' })
      vim.keymap.set('n', '<leader>slr', builtin.lsp_references, { desc = '[S]earch [L]sp [R]eferences' })
      vim.keymap.set('n', '<leader>sls', builtin.lsp_document_symbols, { desc = '[S]earch [L]sp [S]ymbols' })
      vim.keymap.set('n', '<leader>slws', builtin.lsp_workspace_symbols, { desc = '[S]earch [L]sp [W]orkspace [S]ymbols' })
      vim.keymap.set('n', '<leader>slt', builtin.lsp_type_definitions, { desc = '[S]earch [L]sp [T]ype definitions' })
      vim.keymap.set('n', '<leader>sgb', builtin.git_branches, { desc = '[S]earch [G]it [B]ranches' })
      vim.keymap.set('n', '<leader>sgc', builtin.git_commits, { desc = '[S]earch [G]it [C]ommits' })
      vim.keymap.set('n', '<leader>sgf', builtin.git_files, { desc = '[S]earch [G]it [F]iles' })

      vim.keymap.set('n', '<leader>sp', function()
        builtin.find_files {
          cwd = vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy'), ---@diagnostic disable-line
        }
      end, { desc = '[S]earch [G]it [F]iles' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(themes.get_dropdown {
          layout_config = { width = 0.75, height = 0.75 },
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },
}
