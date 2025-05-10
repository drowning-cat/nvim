vim.api.nvim_create_user_command('Format', function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ['end'] = { args.line2, end_line:len() },
    }
  end
  require('conform').format { range = range }
end, { range = true })

vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, { bang = true })

return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    dependencies = {
      {
        'williamboman/mason.nvim',
        opts = {
          ensure_installed = {
            'prettierd',
            'stylua',
            'isort',
            'black',
            'markdownlint',
            'beautysh',
            'deno',
          },
        },
      },
    },
    keys = {
      -- stylua: ignore
      { '<leader>f', function() require('conform').format() end, desc = '[F]ormat buffer' },
      {
        '<leader>tf',
        function()
          local not_disabled = not (vim.b.disable_autoformat or vim.g.disable_autoformat)
          vim.b.disable_autoformat = not_disabled
          vim.g.disable_autoformat = not_disabled
          vim.u.notify(string.format('Disable autoformat: %s', not_disabled), { duration = 2000 })
        end,
        desc = '[T]oggle auto[f]ormat for the current buffer',
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable autoformat on certain filetypes
        local ignore_filetypes = { 'c', 'cpp', 'md', 'sql' }
        if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
          return
        end
        -- Disable with a global or buffer-local variable
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        -- Disable autoformat for files in a certain path
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match '/node_modules/' then
          return
        end
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
      default_format_opts = {
        lsp_format = 'fallback',
        async = true,
      },
      formatters = {
        beautysh = {
          prepend_args = { '-i', '2' },
        },
      },
      formatters_by_ft = {
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        lua = { 'stylua' },
        markdown = { 'deno_fmt' },
        python = { 'isort', 'black' },
        sh = { 'beautysh' },
        bash = { 'beautysh' },
        zsh = { 'beautysh' },
      },
    },
  },
}
