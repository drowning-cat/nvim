local live_multigrep = function(opts)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local make_entry = require 'telescope.make_entry'
  local conf = require('telescope.config').values

  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == '' then
        return nil
      end

      local pieces = vim.split(prompt, '  ')
      local args = { 'rg' }

      if pieces[1] then
        table.insert(args, '-e')
        table.insert(args, pieces[1])
      end

      if pieces[2] then
        local starts_with = function(str)
          return pieces[2]:sub(1, #str) == str
        end
        local ends_with = function(str)
          return pieces[2]:sub(-#str) == str
        end

        local no_auto_glob = ':'
        local glob = '*'
        local match = pieces[2]

        if starts_with(no_auto_glob) then
          match = match:sub(#no_auto_glob + 1)
        else
          match = not starts_with(glob) and glob .. match or match
          match = not ends_with(glob) and match .. glob or match
        end

        table.insert(args, '-g')
        table.insert(args, match)
      end

      local rg_opts = {
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
      }

      return vim.iter({ args, rg_opts }):flatten():totable()
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = 'Multi Grep',
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require('telescope.sorters').empty(),
    })
    :find()
end

return {
  { -- Extend telescope with custom pickers
    'nvim-telescope/telescope.nvim',
    optional = true,
    keys = {
      { '<leader>s/', live_multigrep, desc = '[S]earch Live Grep' },
      { '<leader>s;', live_multigrep, desc = '[S]earch Live Grep' },
    },
  },
}
