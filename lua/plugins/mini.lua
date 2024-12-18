-- Collection of various small independent plugins/modules
--
return {
  {
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'

      -- local statusline_content = function()
      --   local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
      --   local git = statusline.section_git { trunc_width = 40 }
      --   local diff = statusline.section_diff { trunc_width = 75 }
      --   local diagnostics = statusline.section_diagnostics { trunc_width = 75 }
      --   local lsp = statusline.section_lsp { trunc_width = 75 }
      --   local filename = statusline.section_filename { trunc_width = 140 }
      --   local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
      --   local search = statusline.section_searchcount { trunc_width = 75 }
      --
      --   -- You can configure sections in the statusline by overriding their
      --   -- default behavior. For example, here we set the section for
      --   -- cursor location to LINE:COLUMN
      --   --
      --   -- local location = statusline.section_location { trunc_width = 75 }
      --   local location = '%2l:%-2v'
      --
      --   -- https://github.com/declancm/maximize.nvim
      --   local maximize = vim.t.maximized and ' ' or ''
      --
      --   return statusline.combine_groups {
      --     { hl = mode_hl, strings = { mode } },
      --     { hl = 'MiniStatuslineDevinfo', strings = { maximize, git, diff, diagnostics, lsp } },
      --     '%<', -- Mark general truncate point
      --     { hl = 'MiniStatuslineFilename', strings = { filename } },
      --     '%=', -- End left alignment
      --     { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
      --     { hl = mode_hl, strings = { search, location } },
      --   }
      -- end

      statusline.setup {
        -- content = { active = statusline_content },
        -- set use_icons to true if you have a Nerd Font
        use_icons = vim.g.have_nerd_font,
      }

      -- Work with trailing whitespace
      -- `:help mini.trailspace`
      require('mini.trailspace').setup()
      vim.api.nvim_set_hl(0, 'MiniTrailspace', { bg = '#832929' })
      vim.keymap.set('n', '<leader>dw', MiniTrailspace.trim, { desc = '[D]elete trailing [W]hitespace' })

      -- Highlight trailing whitespaces
      -- vim.api.nvim_set_hl(0, 'TrailingWhitespace', { bg = '#832929' })
      -- vim.fn.matchadd('TrailingWhitespace', [[\s\+$]])

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
}
