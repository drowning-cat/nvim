return {
  {
    'echasnovski/mini.nvim',
    config = function()
      -- Better [A]round/[I]nside textobjects:
      --
      --  * va)  - [V]isually select [A]round [)]paren
      --  * yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  * ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.):
      --
      --  * saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      --  * sd'   - [S]urround [D]elete [']quotes
      --  * sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Navigate and manipulate file system
      --
      local files = require 'mini.files'
      files.setup {
        mappings = {
          close = 'q',
          go_in = 'l',
          go_in_plus = 'L',
          go_out = 'h',
          go_out_plus = 'H',
          mark_goto = "'",
          mark_set = 'm',
          reset = '<BS>',
          reveal_cwd = '@',
          show_help = 'g?',
          synchronize = '=',
          trim_left = '<',
          trim_right = '>',
        },
      }
      vim.keymap.set('n', '<leader>of', files.open, { desc = '[O]pen [f]iles mini' })

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'TelescopePrompt', 'mason', 'lazy' },
        callback = function()
          local win = vim.fn.win_getid()
          MiniFiles.close()
          vim.fn.win_gotoid(win)
        end,
      })

      local go_in_plus = function()
        for _ = 1, vim.v.count1 do
          files.go_in { close_on_file = true }
        end
      end

      -- mini.files does not support setting multiple keymaps via files.setup{}
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local map = function(mode, lhs, rhs, opts)
            opts = vim.tbl_extend('keep', opts or {}, { buffer = args.data.buf_id })
            vim.keymap.set(mode, lhs, rhs, opts)
          end

          map('n', '<CR>', go_in_plus)
          map('n', '<Esc>', files.close)
        end,
      })

      -- Simple and easy statusline
      --
      local statusline = require 'mini.statusline'
      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        content = {
          active = function()
            local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
            local git = statusline.section_git { trunc_width = 40 }
            local diff = statusline.section_diff { trunc_width = 75 }
            local diagnostics = statusline.section_diagnostics { trunc_width = 75 }
            local lsp = statusline.section_lsp { trunc_width = 75 }
            local filename = statusline.section_filename { trunc_width = 140 }
            local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
            local search = statusline.section_searchcount { trunc_width = 75 }
            local location = statusline.section_location { trunc_width = 75 }

            -- You can configure sections in the statusline by overriding their
            -- default behavior. For example, here we set the section for
            -- cursor location to LINE:COLUMN
            location = '%2l:%-2v'

            -- https://github.com/declancm/maximize.nvim
            local maximize = vim.t.maximized and '⇱⇲ ' or '' -- ' '

            if vim.bo.filetype == 'neo-tree' then
              return statusline.combine_groups {
                { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
                '%<',
                '%=',
                { hl = mode_hl, strings = { search, '%2l' } },
              }
            end

            return statusline.combine_groups {
              { hl = mode_hl, strings = { mode } },
              { hl = 'MiniStatuslineDevinfo', strings = { maximize, git, diff, diagnostics, lsp } },
              '%<', -- Mark general truncate point
              { hl = 'MiniStatuslineFilename', strings = { filename } },
              '%=', -- End left alignment
              { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
              { hl = mode_hl, strings = { search, location } },
            }
          end,
        },
      }

      -- Work with trailing whitespace
      --
      local trailspace = require 'mini.trailspace'
      trailspace.setup()
      vim.api.nvim_set_hl(0, 'MiniTrailspace', { bg = '#832929' })
      vim.keymap.set('n', '<leader>dw', trailspace.trim, { desc = '[D]elete trailing [W]hitespace' })
      --
      -- Native, without `mini.trailspace`
      --
      -- vim.api.nvim_set_hl(0, 'TrailingWhitespace', { bg = '#832929' })
      -- vim.fn.matchadd('TrailingWhitespace', [[\s\+$]])

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
}
