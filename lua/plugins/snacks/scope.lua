---@module 'snacks'

return {
  'folke/snacks.nvim',
  ---@type snacks.Config
  opts = {
    scope = {
      keys = {
        textobject = {
          ii = {
            linewise = true,
            desc = '<Motion> around scope',
          },
          ai = {
            linewise = true,
            desc = '<Motion> inside scope',
          },
        },
        jump = {
          ['[i'] = {
            desc = 'Jump scope top edge',
          },
          [']i'] = {
            desc = 'Jump scope bottom edge',
          },
        },
      },
    },
  },
  keys = {
    {
      'S',
      mode = 'o',
      desc = 'Delete/Change/Yank around the scope',
      function()
        local operator, count1 = vim.v.operator, vim.v.count1
        if not vim.list_contains({ 'd', 'c', 'y', 'g@' }, operator) then
          return
        end

        local win = vim.api.nvim_get_current_win()

        local dedent = function(start_line, end_line)
          local cursor = vim.api.nvim_win_get_cursor(win)
          vim.cmd(string.format('%d,%d normal <<', start_line, end_line))
          vim.api.nvim_win_set_cursor(win, cursor)
        end

        Snacks.scope.get(function(_scope)
          local buf = _scope.buf

          local cursor = vim.api.nvim_win_get_cursor(win)[1]

          ---@param scope snacks.scope.Scope|nil
          local function get_scope(scope, count)
            if not scope then
              return
            end
            -- FIX: When the cursor is on the edge, select the parent instead of the sibling
            if cursor < scope.from or cursor > scope.to then
              return get_scope(scope:parent(), count)
            end
            if count > 1 then
              -- NOTE: 1 count = 2 hops
              return get_scope(scope:parent(), count - 0.5)
            end
            return scope, scope:inner()
          end

          local scope_outer, scope_inner = get_scope(_scope, count1)

          if not scope_outer or not scope_inner then
            return
          end

          local inner_start, inner_end = scope_inner.from - 1, scope_inner.to - 1
          local outer_start, outer_end = scope_outer.from - 1, scope_outer.to - 1

          -- NOTE: When scope_inner is empty
          if inner_start == outer_start and inner_end == outer_end then
            inner_start, inner_end = inner_start + 1, inner_end - 1
          end

          local ns = vim.api.nvim_create_namespace 'scope_border'

          vim.hl.range(buf, ns, 'Substitute', { outer_start, 0 }, { inner_start - 1, -1 })
          vim.hl.range(buf, ns, 'Substitute', { inner_end + 1, 0 }, { outer_end, -1 })

          vim.defer_fn(function()
            vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

            -- Yank, Delete, Change, -Comment
            if vim.list_contains({ 'd', 'c', 'y' }, operator) then
              local copy = {
                table.unpack(vim.api.nvim_buf_get_lines(buf, outer_start, inner_start, false)),
                table.unpack(vim.api.nvim_buf_get_lines(buf, inner_end + 1, outer_end + 1, false)),
              }
              vim.fn.setreg(vim.v.register, table.concat(copy, '\n'), 'l')
            end

            if operator == 'y' then
              return
            end

            -- Delete, Change, Comment
            dedent(scope_inner.from, scope_inner.to)

            local inner_lines
            if inner_start == inner_end then
              inner_lines = vim.api.nvim_buf_get_lines(buf, inner_start, inner_start + 1, false)
            else
              inner_lines = vim.api.nvim_buf_get_lines(buf, inner_start, inner_end + 1, false)
            end

            local replace_with = function(lines)
              vim.api.nvim_buf_set_lines(buf, outer_start, outer_end + 1, false, lines)
            end

            if operator == 'd' then
              replace_with(inner_lines)
            end
            if operator == 'c' then
              replace_with { '', table.unpack(inner_lines) }
              vim.api.nvim_win_set_cursor(win, { scope_outer.from, 0 })
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-f>', true, false, true), 'n', false)
            end
            if operator == 'g@' then
              local comment_range = function(ln_start, ln_end)
                vim.cmd(string.format('%s,%snorm gcc', ln_start + 1, ln_end + 1))
              end
              comment_range(inner_end + 1, outer_end)
              comment_range(outer_start, inner_start - 1)
            end
          end, 150)
        end, { cursor = false })
      end,
    },
  },
}
