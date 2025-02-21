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
    scope = {
      keys = {
        textobject = {
          ii = {
            min_size = 1,
            linewise = true,
            edge = false,
            treesitter = { enabled = false },
            desc = '<Motion> linewise scope with edge',
          },
          ai = {
            min_size = 1,
            linewise = true,
            edge = true,
            treesitter = { enabled = false },
            desc = '<Motion> linewise scope with edge',
          },
        },
      },
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
      previewers = {
        git = {
          builtin = false,
        },
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
      win = {
        input = {
          keys = {
            ['<C-y>'] = { 'confirm', mode = { 'n', 'i' } },
            ['<C-g>'] = { 'toggle_live_insert', mode = { 'i', 'n' } },
            ['<C-_>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
            ['<C-]>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
            ['<C-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
            ['<C-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
            ['H'] = 'edit_split',
            ['V'] = 'edit_vsplit',
            ['<M-S-i>'] = { 'toggle_hidden', mode = { 'i', 'n' } },
          },
        },
        list = {
          keys = {
            ['<C-g>'] = 'toggle_live_insert',
            ['<C-_>'] = 'list_scroll_down',
            ['<C-]>'] = 'list_scroll_up',
            ['<C-d>'] = 'preview_scroll_down',
            ['<C-u>'] = 'preview_scroll_up',
            ['H'] = 'edit_split',
            ['V'] = 'edit_vsplit',
            ['<M-S-i>'] = 'toggle_hidden',
          },
        },
        preview = {
          keys = {
            ['<C-g>'] = 'toggle_live_insert',
            ['<C-_>'] = 'list_scroll_down',
            ['<C-]>'] = 'list_scroll_up',
            ['<C-d>'] = 'preview_scroll_down',
            ['<C-u>'] = 'preview_scroll_up',
            ['H'] = 'edit_split',
            ['V'] = 'edit_vsplit',
            ['<M-S-i>'] = 'toggle_hidden',
          },
        },
      },
      sources = {
        files = {
          exclude = { '.git', 'node_modules' },
          ignored = true,
          hidden = true,
        },
        grep = {
          exclude = { '.git', 'node_modules' },
          ignored = true,
          hidden = true,
        },
        explorer = {
          ignored = true,
          hidden = true,
          exclude = { '.git' },
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
                ['l'] = { 'l', { 'confirm', 'focus_list' } },
                ['L'] = { 'L', { 'confirm', 'close' } },
                ['o'] = { 'o', { 'pick_win', 'jump' } },
                ['O'] = 'explorer_open',
                ['d'] = 'safe_delete',
              },
            },
          },
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
    {
      'S',
      mode = 'o',
      desc = 'Delete/Change/Yank around the scope',
      function()
        local op = vim.v.operator
        if not vim.list_contains({ 'd', 'c', 'y' }, op) then
          return
        end
        local buf = vim.api.nvim_get_current_buf()
        local win = vim.api.nvim_get_current_win()
        local rpl_line = function(line, with)
          with = with or {}
          vim.api.nvim_buf_set_lines(buf, line, line + 1, false, with)
        end
        local dedent = function(start_line, end_line)
          local cursor = vim.api.nvim_win_get_cursor(win)
          vim.cmd(string.format('%d,%d normal <<', start_line, end_line))
          vim.api.nvim_win_set_cursor(win, cursor)
        end
        local count = vim.v.count1
        Snacks.scope.get(function(_scope)
          local scope = _scope ---@type snacks.scope.Scope|nil
          local i = count * 2
          while scope and i > 2 do
            scope = scope:parent()
            i = i - 1
          end
          if not scope then
            return
          end
          local top, bot = scope.from, scope.to
          if top == bot then
            return
          end
          local ns = vim.api.nvim_create_namespace 'scope_border'
          vim.hl.range(buf, ns, 'Substitute', { top - 1, 0 }, { top - 1, -1 })
          vim.hl.range(buf, ns, 'Substitute', { bot - 1, 0 }, { bot - 1, -1 })
          vim.defer_fn(function()
            local copy = table.concat({ vim.fn.getline(top), vim.fn.getline(bot) }, '\n')
            vim.fn.setreg(vim.v.register, copy, 'l')
            if op == 'd' then
              dedent(top + 1, bot - 1)
              rpl_line(top - 1)
              rpl_line(bot - 2)
            end
            if op == 'c' then
              local indent = vim.fn.indent(top)
              local pad = string.rep(' ', indent)
              dedent(top + 1, bot - 1)
              rpl_line(top - 1, { pad })
              rpl_line(bot - 1)
              vim.api.nvim_win_set_cursor(win, { top, indent })
            end
            vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
          end, 150)
        end, { cursor = false })
      end,
    },

    { '<leader>.',  function() Snacks.scratch() end, desc = 'Toggle Scratch buffer' },
    { '<leader>S',  function() Snacks.scratch.select() end, desc = 'Select [S]cratch buffer' },
    { '<leader>cR', function() Snacks.rename.rename_file() end, desc = '[R]ename File' },
    { '<leader>bo', function() Snacks.bufdelete.other() end, desc = '[B]uffer delete [o]ther' },
    { '<leader>bd', function() Snacks.bufdelete() end, desc = '[B]uffer [d]elete' },
    { '<leader>bD', '<cmd>:bd<cr>', desc = '[B]uffer and window [D]elete' },
    { '<leader>q', '<leader>bd', remap = true, desc = '[q]uit buffer (see <leader>bd)' },
    { '<leader>Q', '<leader>bD', remap = true, desc = '[Q]uit window (see <leader>bD)' },
    { '<leader>z', function() Snacks.zen() end, desc = 'Toggle [z]en mode' },

    { '<leader>G', function() Snacks.lazygit() end, desc = 'Lazy[G]it' },
    { '<leader>Gf', function() Snacks.lazygit.log_file() end, desc = 'Lazy[G]it current [f]ile history' },
    { '<leader>Gl', function() Snacks.lazygit.log() end, desc = 'Lazy[G]it [l]og (cwd)' },

    { '<leader>gB', function() Snacks.gitbrowse() end, desc = '[G]it [B]rowse', mode = { 'n', 'v' } },

    { '<leader>sgb', function() Snacks.picker.git_branches() end, desc = '[S]earch [g]it [b]ranches' },
    { '<leader>sgd', function() Snacks.picker.git_diff() end, desc = '[S]earch [g]it [d]iff (Hunks)' },
    { '<leader>sgf', function() Snacks.picker.git_files() end, desc = '[S]earch [g]it [f]iles' },
    { '<leader>sgg', function() Snacks.picker.git_grep() end, desc = '[S]earch [g]it [g]rep' },
    { '<leader>sgl', function() Snacks.picker.git_log() end, desc = '[S]earch [g]it [l]og' },
    { '<leader>sgL', function() Snacks.picker.git_log_line() end, desc = '[S]earch [g]it log [L]ine' },
    { '<leader>sgF', function() Snacks.picker.git_log_file() end, desc = '[S]earch [g]it log [F]iles' },
    { '<leader>sgs', function() Snacks.picker.git_status() end, desc = '[S]earch [g]it [s]tatus' },
    { '<leader>sgS', function() Snacks.picker.git_stash() end, desc = '[S]earch [g]it [S]stash' },

    { '<leader>sa', function() Snacks.picker() end, desc = '[S]earch [a]ll pickers' },
    { '<leader>ss', function() Snacks.picker.smart() end, desc = '[S]earch [S]mart' },
    { '\\', function() Snacks.explorer() end, desc = 'Toggle explorer' },
    { '<leader>se', function() Snacks.picker.explorer { layout = 'floating_sidebar', auto_close = true } end, desc = '[S]earch [e]xplorer' },

    { '<leader>sf', function() Snacks.picker.files() end, desc = '[S]earch [f]iles' },
    ---@diagnostic disable-next-line: assign-type-mismatch
    { '<leader>sN', function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end, desc = '[S]earch [N]eovim files' },
    { '<leader>sP', function() Snacks.picker.projects() end, desc = '[S]earch [P]rojects' },
    { '<leader>s.', function() Snacks.picker.recent() end, desc = '[S]earch Recent files' },

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
