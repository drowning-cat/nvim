---@module 'snacks'

local plugins = {}

---@module 'noice'
table.insert(plugins, {
  'folke/noice.nvim',
  -- stylua: ignore
  opts = {
    cmdline   = { enabled = false },
    messages  = { enabled = false },
    popupmenu = { enabled = false },
    notify    = { enabled = false },
    lsp = {
      override  = {
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
        ['vim.lsp.util.stylize_markdown'] = true,
      },
      progress  = { enabled = false },
      hover     = { enabled = true },
      signature = { enabled = true },
      message   = { enabled = true },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        local map_scroll = function(key, delta)
          vim.keymap.set({ 'n', 'i', 's' }, key, function()
            if not require('noice.lsp').scroll(delta) then
              return key
            end
          end, { silent = true, expr = true })
        end
        map_scroll('<C-]>', 4)
        map_scroll('<C-_>', -4)
      end,
    })
  end,
})

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
  'folke/todo-comments.nvim',
  optional = true,
  -- stylua: ignore
  keys = {
    ---@diagnostic disable-next-line: undefined-field
    { '<leader>st', function() Snacks.picker.todo_comments() end, desc = '[S]earch [t]odo' },
    ---@diagnostic disable-next-line: undefined-field
    { '<leader>sT', function () Snacks.picker.todo_comments { keywords = { 'TODO', 'FIX', 'FIXME' } } end, desc = '[S]earc [T]odo/Fix/Fixme' },
  },
})

table.insert(plugins, {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  dependencies = 'echasnovski/mini.icons',
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Filter notifications without enabled notifier
        local notiy = vim.notify
        vim.notify = function(msg, lvl, opts) ---@diagnostic disable-line: duplicate-set-field
          if opts and vim.list_contains({ 'snacks_picker_layout_change' }, opts.id) then
          else
            notiy(msg, lvl, opts)
          end
        end

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
    dashboard = nil,
    picker = nil,
    scope = nil,
    --------------------
    bigfile = {
      notify = false,
    },
    explorer = {
      replace_netrw = false,
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
      enabled = true,
    },
    terminal = {
      enabled = true,
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
    ---@type table<string, snacks.win.Config>
    styles = {
      lazygit = {
        relative = 'editor',
        width = 0.95,
      },
      scratch = {
        relative = 'editor',
        width = 125,
        height = 35,
        backdrop = false,
      },
      terminal = {
        relative = 'editor',
        on_win = function(win)
          if vim.g.terminal_size then
            vim.api.nvim_win_set_height(win.win, vim.g.terminal_size)
          end
        end,
        on_close = function(win)
          vim.g.terminal_size = vim.api.nvim_win_get_height(win.win)
        end,
        wo = {
          winbar = '',
        },
      },
    },
  },
  -- stylua: ignore
  keys = {
    { '<leader>.',  function() Snacks.scratch() end, desc = 'Toggle Scratch buffer' },

    { '<M-`>', mode = { 'n', 't' }, function() Snacks.terminal() end },

    { '<leader>cR', function() Snacks.rename.rename_file() end, desc = '[R]ename File' },
    { '<leader>bo', function() Snacks.bufdelete.other() end, desc = '[B]uffer delete [o]ther' },
    { '<leader>bd', function() Snacks.bufdelete() end, desc = '[B]uffer [d]elete' },
    { '<leader>bD', function()
      if #vim.fn.win_findbuf(vim.fn.bufnr('%')) > 1 then
        vim.cmd 'quit'
      else
        vim.cmd 'bdelete'
      end
    end, desc = '[B]uffer and window [D]elete' },
    { '<leader>q', '<leader>bd', remap = true, desc = '[q]uit buffer (see <leader>bd)' },
    { '<leader>Q', '<leader>bD', remap = true, desc = '[Q]uit window (see <leader>bD)' },
    { '<leader>z', function() Snacks.zen() end, desc = 'Toggle [z]en mode' },

    { '<leader>gg', function() Snacks.lazygit() end, desc = 'Lazy[g]it' },
    { '<leader>gf', function() Snacks.lazygit.log_file() end, desc = 'Lazy[g]it current [f]ile history' },
    { '<leader>gl', function() Snacks.lazygit.log() end, desc = 'Lazy[g]it [l]og (cwd)' },
    { '<leader>gB', function() Snacks.gitbrowse() end, desc = '[G]it [B]rowse', mode = { 'n', 'v' } },

    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = '[G]oto [d]efinition' },
    { 'gD', function() Snacks.picker.lsp_declarations() end, desc = '[G]oto [D]eclaration' },
    { 'gR', function() Snacks.picker.lsp_references() end, nowait = true, desc = '[G]oto [r]eferences' },
    { 'gI', function() Snacks.picker.lsp_implementations() end, desc = '[G]oto [I]mplementation' },
    { 'gy', function() Snacks.picker.lsp_type_definitions() end, desc = '[G]oto T[y]pe Definition' },

    { '<leader>s<space>', function() Snacks.picker() end, desc = '[S]earch all Pickers' },
    { '<leader>ss', function() Snacks.picker.smart() end, desc = '[S]earch [s]mart' },

    { '<leader>sS',  function() Snacks.scratch.select() end, desc = 'Select [S]cratch buffer' },

    { '\\', '<leader>se', remap = true },
    { '<leader>se', function() Snacks.picker.explorer { cwd = vim.u.find_root() } end, desc = '[S]each [e]xplorer (root)' },
    { '<leader>s.e', function() Snacks.picker.explorer { cwd = nil } end, desc = '[S]each [e]xplorer (cwd)' },
    { '<leader>s~e', function() Snacks.picker.explorer { cwd = '~' } end, desc = '[S]each [e]xplorer (home)' },
    { '<leader>sE', function() Snacks.picker.explorer { cwd = vim.u.find_root(), layout = 'floating_sidebar', auto_close = true } end, desc = '[S]earch [E]xplorer float (root)' },
    { '<leader>s.E', function() Snacks.picker.explorer { cwd = nil, layout = 'floating_sidebar', auto_close = true } end, desc = '[S]earch [E]xplorer float (cwd)' },
    { '<leader>s~E', function() Snacks.picker.explorer { cwd = '~', layout = 'floating_sidebar', auto_close = true } end, desc = '[S]earch [E]xplorer float (home)' },

    ---@diagnostic disable-next-line: assign-type-mismatch
    { '<leader>sf', function() Snacks.picker.files { cwd = vim.u.find_root(), layout = { preset = 'vertical_mini', preview = false } } end, desc = '[S]earch [f]iles (root)' },
    ---@diagnostic disable-next-line: assign-type-mismatch
    { '<leader>s.f', function() Snacks.picker.files { cwd = nil, layout = { preset = 'vertical_mini', preview = false } } end, desc = '[S]earch [f]iles (cwd)' },
    ---@diagnostic disable-next-line: assign-type-mismatch
    { '<leader>s~f', function() Snacks.picker.files { cwd = '~', layout = { preset = 'vertical_mini', preview = false } } end, desc = '[S]earch [f]iles (home)' },

    { '<leader>sF', function() Snacks.picker.files { cwd = vim.u.find_root() } end, desc = '[S]earch [F]iles (root)' },
    { '<leader>s.F', function() Snacks.picker.files { cwd = nil } end, desc = '[S]earch [F]iles (cwd)' },
    { '<leader>s~F', function() Snacks.picker.files { cwd = '~' } end, desc = '[S]earch [F]iles (cwd)' },

    { '<leader>s;', function() Snacks.picker.grep { cwd = vim.u.find_root() } end, desc = '[S]earch Grep' },
    ---@diagnostic disable-next-line: assign-type-mismatch
    { '<leader>s.;', function() Snacks.picker.grep { cwd = nil } end, desc = '[S]earch Grep (cwd)' },
    { '<leader>s~;', function() Snacks.picker.grep { cwd = '~' } end, desc = '[S]earch Grep (home)' },
    { '<leader>sw', function() Snacks.picker.grep_word() end, desc = '[S]earch [w]ord or visual selection', mode = { 'n', 'x' } },

    { '<leader>sp', function() Snacks.picker.projects() end, desc = '[S]earch [p]rojects' },
    { '<leader>sN', function() Snacks.picker.files { cwd = vim.fn.stdpath('config') } end, desc = '[S]earch [N]eovim files' },
    { '<leader>sr', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
    { '<leader>sR', function() Snacks.picker.recent() end, desc = '[S]earch Recent files' },

    { '<leader><space>', function() Snacks.picker.buffers() end, desc = '[S]earch Buffers' },
    { '<leader>s,', function() Snacks.picker.buffers() end, desc = '[S]earch Buffers' },
    { '<leader>s:', function() Snacks.picker.command_history() end, desc = '[S]earch Command history' },
    { "<leader>s'", function() Snacks.picker.registers() end, desc = '[S]earch Registers' },
    { '<leader>s?', function() Snacks.picker.search_history() end, desc = '[S]earch Search history' },
    { '<leader>sA', function() Snacks.picker.autocmds() end, desc = '[S]earch [A]utocmds' },
    { '<leader>s/', function() Snacks.picker.lines() end, desc = '[S]earch buffer Lines' },
    { '<leader>sb', function() Snacks.picker.grep_buffers() end, desc = '[S]earch in open [b]uffers' },
    { '<leader>sc', function() Snacks.picker.commands() end, desc = '[S]earch [C]ommands' },
    { '<leader>sC', function() Snacks.picker.colorschemes() end, desc = '[S]earch [c]olorschemes' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [d]iagnostics' },
    { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = '[S]earch Buffer [D]iagnostics' },
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [h]elp pages' },
    { '<leader>sH', function() Snacks.picker.highlights() end, desc = '[S]earch [H]ighlights' },
    { '<leader>si', function() Snacks.picker.icons() end, desc = '[S]earch [i]cons' },
    { '<leader>sj', function() Snacks.picker.jumps() end, desc = '[S]earch [j]umps' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [k]eymaps' },
    { '<leader>sql', function() Snacks.picker.qflist() end, desc = '[S]earch [q]uickfix list' },
    { '<leader>sqL', function() Snacks.picker.loclist() end, desc = '[S]earch location list' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = '[S]earch [m]arks' },
    { '<leader>sM', function() Snacks.picker.man() end, desc = '[S]earch [M]an pages' },
    { '<leader>su', function() Snacks.picker.undo() end, desc = '[S]earch [u]ndo history' },

    { '<leader>sg<space>', function() Snacks.picker.pick { source = 'git_pickers' } end, desc = '[S]earch [g]it all Pickers' },
    { '<leader>sgb', function() Snacks.picker.git_branches() end, desc = '[S]earch [g]it [b]ranches' },
    { '<leader>sgd', function() Snacks.picker.git_diff() end, desc = '[S]earch [g]it [d]iff (Hunks)' },
    { '<leader>sgf', function() Snacks.picker.git_files() end, desc = '[S]earch [g]it [f]iles' },
    { '<leader>sgg', function() Snacks.picker.git_grep() end, desc = '[S]earch [g]it [g]rep' },
    { '<leader>sgl', function() Snacks.picker.git_log() end, desc = '[S]earch [g]it [l]og' },
    { '<leader>sgL', function() Snacks.picker.git_log_line() end, desc = '[S]earch [g]it log [L]ine' },
    { '<leader>sgF', function() Snacks.picker.git_log_file() end, desc = '[S]earch [g]it log [F]iles' },
    { '<leader>sgs', function() Snacks.picker.git_status() end, desc = '[S]earch [g]it [s]tatus' },
    { '<leader>sgS', function() Snacks.picker.git_stash() end, desc = '[S]earch [g]it [S]stash' },

    { '<leader>sl<space>', function() Snacks.picker.pick { source = 'lsp_pickers' } end, desc = '[S]earch [L]SP all Pickers' },
    { '<leader>sls', function() Snacks.picker.lsp_symbols() end, desc = '[S]earch [L]SP [s]ymbols' },
    { '<leader>slw', function() Snacks.picker.lsp_workspace_symbols() end, desc = '[S]earch [L]SP [w]orkspace Symbols' },
  },
})

return plugins
