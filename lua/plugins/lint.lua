return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      {
        'mason-org/mason.nvim',
        opts = {
          ensure_installed = {
            'hadolint',
            'jsonlint',
            'vale',
            'tflint',
          },
        },
      },
    },
    config = function()
      local lint = require 'lint'

      lint.linters_by_ft = lint.linters_by_ft or {}
      lint.linters_by_ft['dockerfile'] = { 'hadolint' }
      lint.linters_by_ft['json'] = { 'jsonlint' }
      lint.linters_by_ft['markdown'] = { 'vale' }
      lint.linters_by_ft['text'] = { 'vale' }
      lint.linters_by_ft['terraform'] = { 'tflint' }

      -- Disable default linters
      lint.linters_by_ft['clojure'] = nil -- { 'clj-kondo' }
      lint.linters_by_ft['inko'] = nil ----- { 'inko' }
      lint.linters_by_ft['janet'] = nil ---- { 'janet' }
      lint.linters_by_ft['rst'] = nil ------ { 'vale' }
      lint.linters_by_ft['ruby'] = nil ----- { 'ruby' }

      vim.g.cspell = false

      vim.keymap.set('n', '<leader>ts', function()
        if vim.g.cspell then
          vim.diagnostic.reset(lint.get_namespace 'cspell')
        else
          lint.try_lint 'cspell'
        end
        vim.g.cspell = not vim.g.cspell
      end, { desc = '[T]oggle c[s]pell linter' })

      -- Create autocommand which carries out the actual linting on the specified events
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown
          if vim.opt_local.modifiable:get() then
            lint.try_lint()
            if vim.g.cspell then
              lint.try_lint 'cspell'
            end
          end
        end,
      })
    end,
  },
}
