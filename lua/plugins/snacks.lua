---@module 'snacks'

local plugins = {}

---@module 'which-key'
table.insert(plugins, {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    preset = 'modern',
    icons = {
      mappings = false,
    },
    win = {
      width = 0.98,
      title_pos = 'left',
    },
  },
})

---@module 'trouble'
table.insert(plugins, {
  'folke/trouble.nvim',
  cmd = 'Trouble',
  opts = {
    win = {
      size = 10,
    },
    modes = {
      symbols = {
        win = {
          size = 50,
        },
      },
    },
  },
  specs = {
    'folke/snacks.nvim',
    opts = function(_, opts)
      return vim.tbl_deep_extend('force', opts or {}, {
        picker = {
          actions = require('trouble.sources.snacks').actions,
          win = {
            input = {
              keys = {
                ['<C-t>'] = { 'trouble_open', mode = { 'n', 'i' } },
              },
            },
          },
        },
      })
    end,
  },
  -- stylua: ignore
  keys = {
    { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
    { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics (Trouble)' },
    { '<leader>cs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = '[S]ymbols (Trouble)' },
    { '<leader>cl', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', desc = '[L]sp definitions / references / ... (Trouble)' },
    { '<leader>xl', '<cmd>Trouble qflist toggle<cr>', desc = '[Q]uickfix List (Trouble)' },
    { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = '[L]ocation List (Trouble)' },
  },
})

---@module 'persistence'
table.insert(plugins, {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {},
  -- stylua: ignore
  keys = {
    { '<leader>S.', function() require('persistence').select() end, desc = '[S]ession select' },
    { '<leader>Sl', function() require('persistence').load() end, desc = '[S]ession [l]oad (for current directory)' },
    { '<leader>SL', function() require('persistence').load() end, desc = '[S]ession load [L]ast' },
    { '<leader>Sd', function() require('persistence').stop() end, desc = '[S]ession [d]elete' },
  },
})

table.insert(plugins, {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  dependencies = {
    'echasnovski/mini.icons',
    {
      'folke/todo-comments.nvim',
      optional = true,
      -- stylua: ignore
      keys = {
        ---@diagnostic disable-next-line: undefined-field
        { '<leader>st', function () Snacks.picker.todo_comments { keywords = { 'TODO', 'FIX', 'FIXME' } } end, desc = 'Todo/Fix/Fixme' },
        ---@diagnostic disable-next-line: undefined-field
        { '<leader>sT', function() Snacks.picker.todo_comments() end, desc = 'Todo' },
      },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        Snacks.toggle.option('spell', { name = '[s]pelling' }):map '<leader>ts'
        Snacks.toggle.option('wrap', { name = '[w]rap' }):map '<leader>tw'
        Snacks.toggle.option('relativenumber', { name = 're[L]ative number' }):map '<leader>tL'
        Snacks.toggle.line_number({ name = '[l]ine number' }):map '<leader>tl'
        Snacks.toggle.option('conceallevel', { name = '[c]onceallevel', off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>tc'
        Snacks.toggle.treesitter({ name = '[T]reesitter' }):map '<leader>tT'
        Snacks.toggle.option('background', { name = 'dark [B]ackground', off = 'light', on = 'dark' }):map '<leader>tB'
        Snacks.toggle.inlay_hints({ name = 'Inlay [h]ints' }):map '<leader>th'
        ---@diagnostic disable-next-line: redundant-parameter
        Snacks.toggle.indent({ name = 'Indent [G]uides' }):map '<leader>tg'
        Snacks.toggle
          .new({
            name = '[d]iagnostics virtual text',
            get = function()
              local vt = vim.diagnostic.config().virtual_text
              return vt ~= nil and vt ~= false
            end,
            set = function(vt)
              vim.diagnostic.config { virtual_text = vt }
            end,
          })
          :map '<leader>td'
        Snacks.toggle.diagnostics({ name = '[D]iagnostics' }):map '<leader>tD'

        vim.api.nvim_create_user_command('LazyGit', function()
          Snacks.lazygit()
        end, {})
        vim.api.nvim_create_user_command('LazyDocker', function()
          Snacks.terminal 'lazydocker'
        end, {})
      end,
    })
  end,
  ---@type snacks.Config
  opts = {
    bigfile = {
      enabled = true,
    },
    gitbrowse = {
      remote_patterns = {
        { '^git@github%.com%.(.+):(.+).git$', 'https://github.com/%2' },
      },
    },
    image = {
      enabled = true,
    },
    quickfile = {
      enabled = true,
    },
    statuscolumn = {
      left = { 'git', 'mark', 'fold' },
      right = {},
    },
    toggle = {
      notify = false,
      wk_desc = '[T]oggle ',
    },
    words = {
      enabled = true,
    },
    zen = {
      toggles = {
        dim = false,
      },
      win = {
        width = 0.65,
        backdrop = {
          transparent = false,
          blend = 99,
        },
      },
    },
    picker = {
      actions = {
        toggle_live_insert = function(picker)
          picker:action 'toggle_live'
          picker:focus 'input'
        end,
      },
      layout = {
        preset = function()
          return vim.o.columns >= 120 and 'better_telescope' or 'vertical'
        end,
      },
      layouts = {
        better_telescope = {
          reverse = true,
          layout = {
            box = 'horizontal',
            width = 0.85,
            height = 0.9,
            backdrop = false,
            {
              box = 'vertical',
              border = 'single',
              title = '{title} {live} {flags}',
              { win = 'list', border = 'none' },
              { win = 'input', height = 1, border = 'top' },
            },
            { win = 'preview', width = 0.5, border = 'single', title = '{preview}' },
          },
        },
        floating_sidebar = {
          cycle = true,
          layout = {
            box = 'horizontal',
            position = 'float',
            height = 0.95,
            width = 0,
            border = 'rounded',
            {
              box = 'vertical',
              width = 40,
              min_width = 40,
              { win = 'input', height = 1, title = '{title} {live} {flags}', border = 'single' },
              { win = 'list' },
            },
            { win = 'preview', width = 0, border = 'left' },
          },
        },
      },
      sources = {
        explorer = {
          ignored = true,
          hidden = true,
          exclude = { '.git' },
          layout = {
            preview = 'main',
            auto_hide = { 'preview' },
            layout = {
              backdrop = false,
              width = 40,
              min_width = 40,
              height = 0,
              position = 'left',
              border = 'none',
              box = 'vertical',
              {
                win = 'input',
                height = 1,
                border = 'single',
                title = '{title} {live} {flags}',
                title_pos = 'center',
              },
              { win = 'list', border = 'none' },
              { win = 'preview', title = '{preview}', height = 0.4, border = 'top' },
            },
          },
          actions = {
            safe_delete = function(picker)
              local selected = picker:selected { fallback = true }
              local has_root = vim.iter(selected):any(function(v)
                return not v.parent
              end)
              if not has_root then
                picker:action 'explorer_del'
              end
            end,
            close_preview = function(picker)
              picker.preview:close()
            end,
          },
          win = {
            input = {
              keys = {
                ['h'] = 'focus_list',
                ['j'] = 'focus_list',
              },
            },
            list = {
              keys = {
                ['L'] = { 'L', { 'confirm', 'close' } },
                ['l'] = { 'l', { 'confirm', 'focus_list' } },
                ['o'] = { 'o', { 'pick_win', 'jump' } },
                ['O'] = 'explorer_open',
                ['d'] = 'safe_delete',
              },
            },
          },
        },
      },
      win = {
        input = {
          keys = {
            ['<C-g>'] = { 'toggle_live_insert', mode = { 'i', 'n' } },
            ['<C-y>'] = { 'confirm', mode = { 'n', 'i' } },
            ['<C-_>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
            ['<C-]>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
            ['<C-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
            ['<C-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
            ['H'] = { 'edit_split', mode = 'n' },
            ['V'] = { 'edit_vsplit', mode = 'n' },
          },
        },
        list = {
          keys = {
            ['<C-g>'] = 'toggle_live_insert',
          },
        },
        preview = {
          keys = {
            ['<C-g>'] = 'toggle_live_insert',
          },
        },
      },
    },
    dashboard = {
      preset = {
        keys = {
          { icon = ' ', key = 'n', desc = 'New', action = ':ene' },
          { icon = ' ', key = 'i', desc = 'Insert', action = ':ene | startinsert' },
          { icon = ' ', key = 'f', desc = 'Find', action = ":lua Snacks.dashboard.pick('files')" },
          { icon = ' ', key = 'g', desc = 'Grep', action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = ' ', key = 'r', desc = 'Recent', action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
          { icon = '󰦛 ', key = 's', desc = 'Session', section = 'session' },
          { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
        },
      },
      sections = {
        { title = { 'Recent Files', hl = 'Special' }, align = 'center', padding = 1 },
        { section = 'recent_files', limit = 10, padding = 2 },
        { title = { 'Quick Links', hl = 'Special' }, align = 'center', padding = 1 },
        { section = 'keys', padding = 2 },
      },
    },
    styles = {
      scratch = {
        width = 125,
        height = 40,
        backdrop = false,
        relative = 'editor',
      },
    },
  },
  -- stylua: ignore
  keys = {
    { '<leader>.',  function() Snacks.scratch() end, desc = 'Toggle Scratch buffer' },
    { '<leader>S',  function() Snacks.scratch.select() end, desc = 'Select [S]cratch buffer' },
    { '<leader>cR', function() Snacks.rename.rename_file() end, desc = '[R]ename File' },
    { '<leader>bo', function() Snacks.bufdelete.other() end, desc = '[B]uffer delete [o]ther' },
    { '<leader>bd', function() Snacks.bufdelete() end, desc = '[B]uffer [d]elete' },
    { '<leader>bD', '<cmd>:bd<cr>', desc = '[B]uffer and window [D]elete' },
    { '<leader>q', '<leader>bd', remap = true, desc = '[q]uit buffer (see <leader>bd)' },
    { '<leader>Q', '<leader>bD', remap = true, desc = '[Q]uit window (see <leader>bD)' },
    { '<leader>z', function() Snacks.zen() end, desc = 'Toggle [z]en mode' },

    { '<leader>g', function() Snacks.lazygit() end, desc = 'Lazy[g]it' },
    { '<leader>gf', function() Snacks.lazygit.log_file() end, desc = 'Lazy[g]it current [f]ile history' },
    { '<leader>gl', function() Snacks.lazygit.log() end, desc = 'Lazy[g]it [l]og (cwd)' },
    { '<leader>gB', function() Snacks.gitbrowse() end, desc = '[G]it [B]rowse', mode = { 'n', 'v' } },

    { '<leader>sa', function() Snacks.picker() end, desc = '[S]earch [a]ll pickers' },
    { '<leader>ss', function() Snacks.picker.smart() end, desc = '[S]earch [S]mart' },
    { '\\', function() Snacks.explorer() end, desc = 'Toggle explorer' },
    { '<leader>se', function() Snacks.picker.explorer { layout = 'floating_sidebar', auto_close = true } end, desc = '[S]earch [e]xplorer' },

    { '<leader>sf', function() Snacks.picker.files() end, desc = '[S]earch [f]iles' },
    ---@diagnostic disable-next-line: assign-type-mismatch
    { '<leader>sN', function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end, desc = '[S]earch [N]eovim files' },
    { '<leader>sP', function() Snacks.picker.projects() end, desc = '[S]earch [P]rojects' },
    { '<leader>s.', function() Snacks.picker.recent() end, desc = '[S]earch Recent files' },

    { '<leader>sgf', function() Snacks.picker.git_files() end, desc = '[S]earch [g]it [f]iles' },
    { '<leader>sgl', function() Snacks.picker.git_log() end, desc = '[S]earch [g]it [l]og' },
    { '<leader>sgL', function() Snacks.picker.git_log_line() end, desc = '[S]earch [g]it log [L]ine' },
    { '<leader>sgf', function() Snacks.picker.git_log_file() end, desc = '[S]earch [g]it log [f]ile' },
    { '<leader>sgs', function() Snacks.picker.git_status() end, desc = '[S]earch [g]it [s]tatus' },
    { '<leader>sgd', function() Snacks.picker.git_diff() end, desc = '[S]earc [g]it [d]iff (Hunks)' },

    { '<leader>sw', function() Snacks.picker.grep_word() end, desc = '[S]earch [w]ord or visual selection', mode = { 'n', 'x' } },
    { '<leader>s;', function() Snacks.picker.grep() end, desc = '[S]earch Grep' },
    { '<leader>s,', function() Snacks.picker.buffers() end, desc = '[S]earch Buffers' },
    { '<leader>s:', function() Snacks.picker.command_history() end, desc = '[S]earch Command history' },
    { '<leader>sn', function() Snacks.picker.notifications() end, desc = '[S]earch [N]otification history' },
    { "<leader>s'", function() Snacks.picker.registers() end, desc = '[S]earch Registers' },
    { '<leader>s?', function() Snacks.picker.search_history() end, desc = '[S]earch Search history' },
    { '<leader>sA', function() Snacks.picker.autocmds() end, desc = '[S]earch [A]utocmds' },
    { '<leader>s/', function() Snacks.picker.lines() end, desc = '[S]earch buffer Lines' },
    { '<leader>sb', function() Snacks.picker.grep_buffers() end, desc = '[S]earch in open [b]uffers' },
    { '<leader>sc', function() Snacks.picker.colorschemes() end, desc = '[S]earch [c]olorschemes' },
    { '<leader>sC', function() Snacks.picker.commands() end, desc = '[S]earch [C]ommands' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [d]iagnostics' },
    { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = '[S]earch Buffer [D]iagnostics' },
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [h]elp pages' },
    { '<leader>sH', function() Snacks.picker.highlights() end, desc = '[S]earch [H]ighlights' },
    { '<leader>si', function() Snacks.picker.icons() end, desc = '[S]earch [i]cons' },
    { '<leader>sj', function() Snacks.picker.jumps() end, desc = '[S]earch [j]umps' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [k]eymaps' },
    { '<leader>sl', function() Snacks.picker.loclist() end, desc = '[S]earch [l]ocation List' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = '[S]earch [m]arks' },
    { '<leader>sM', function() Snacks.picker.man() end, desc = '[S]earch [M]an pages' },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = '[S]earch [q]uickfix List' },
    { '<leader>sR', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
    { '<leader>su', function() Snacks.picker.undo() end, desc = '[S]earch [u]ndo history' },
    { '<leader>sls', function() Snacks.picker.lsp_symbols() end, desc = '[S]earch [L]SP [s]ymbols' },
    { '<leader>slw', function() Snacks.picker.lsp_workspace_symbols() end, desc = '[S]earch [L]SP [w]orkspace Symbols' },

    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = '[G]oto [d]efinition' },
    { 'gD', function() Snacks.picker.lsp_declarations() end, desc = '[G]oto [D]eclaration' },
    { 'gR', function() Snacks.picker.lsp_references() end, nowait = true, desc = '[G]oto [r]eferences' },
    { 'gI', function() Snacks.picker.lsp_implementations() end, desc = '[G]oto [I]mplementation' },
    { 'gy', function() Snacks.picker.lsp_type_definitions() end, desc = '[G]oto T[y]pe Definition' },
  },
})

return plugins
