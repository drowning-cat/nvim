return {
  {
    'echasnovski/mini.nvim',
    config = function()
      -- Better [A]round/[I]nside textobjects:
      --  * va)  - [V]isually select [A]round [)]paren
      --  * yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  * ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.):
      --  * saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      --  * sd'   - [S]urround [D]elete [']quotes
      --  * sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

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

            if vim.bo.filetype == 'neo-tree' then
              return statusline.combine_groups {
                { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
                '%<',
                '%=',
                { hl = mode_hl, strings = { search, '%2l' } },
              }
            end

            -- https://github.com/declancm/maximize.nvim
            local maximize = vim.t.maximized and ' 󰊓 ' or ''

            return statusline.combine_groups {
              { hl = mode_hl, strings = { mode } },
              { hl = 'Cursor', strings = { maximize } },
              { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics, lsp } },
              '%<',
              { hl = 'MiniStatuslineFilename', strings = { filename } },
              '%=',
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
