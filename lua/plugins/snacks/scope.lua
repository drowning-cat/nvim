---@module 'snacks'

---@param buf integer
---@param line_number integer
---@param count integer
local get_scope = function(buf, line_number, count)
  ---@param from integer
  ---@param dir -1|1
  local ilines = function(from, dir)
    local lnum = from
    local min, max = 1, vim.api.nvim_buf_line_count(buf)
    return function()
      if lnum <= min or lnum >= max then
        return nil
      end
      local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
      local curr = lnum
      lnum = lnum + dir
      return curr, line
    end
  end

  ---@param line_number integer
  local _find_scope = function(line_number) ---@diagnostic disable-line: redefined-local
    -- Find indent
    local i, j ---@type integer, integer
    for lnum, line in ilines(line_number, -1) do
      if vim.trim(line) ~= '' then
        i = lnum
        break
      end
    end
    for lnum, line in ilines(line_number, 1) do
      if vim.trim(line) ~= '' then
        j = lnum
        break
      end
    end
    if not i or not j then
      return nil, -1, -1
    end
    local indent = math.min(vim.fn.indent(i), vim.fn.indent(j))
    if indent < 1 then
      return nil, -1, -1
    end

    -- Find edges
    local outer_start, outer_end ---@type integer?, integer?
    for lnum, line in ilines(i, -1) do
      if vim.trim(line) ~= '' and vim.fn.indent(lnum) < indent then
        outer_start = lnum
        break
      end
    end
    for lnum, line in ilines(j, 1) do
      if vim.trim(line) ~= '' and vim.fn.indent(lnum) < indent then
        outer_end = lnum
        break
      end
    end
    if not outer_start or not outer_end then
      return nil, -1, -1
    end

    return outer_start, outer_end, indent
  end

  ---@param line_number integer
  ---@param count integer
  ---@return integer?, integer, integer
  local find_scope = function(line_number, count) ---@diagnostic disable-line: redefined-local
    local outer_start, outer_end, indent

    -- Include border
    -- outer_start, outer_end, indent = table.unpack(vim
    --   .iter({
    --     { _find_scope(line_number) },
    --     { _find_scope(line_number - 1) },
    --     { _find_scope(line_number + 1) },
    --   })
    --   :fold({}, function(acc, val)
    --     if (acc[1] and val[1] and val[3] > acc[3]) or (val[1] and not acc[1]) then
    --       acc = val
    --     end
    --     return acc
    --   end))
    -- count = count - 1

    while count >= 1 do
      outer_start, outer_end, indent = _find_scope(line_number)
      if not outer_start then
        return nil, -1, -1
      end
      count = count - 1
      line_number = outer_start
    end
    return outer_start, outer_end, indent
  end

  local outer_start, outer_end, indent = find_scope(line_number, count)
  if not outer_start then
    return nil
  end

  local inner_start, inner_end = outer_start + 1, outer_end - 1

  local scope = {
    outer_start = outer_start,
    outer_end = outer_end,
    inner_start = inner_start,
    inner_end = inner_end,
    indent = indent,
    indent_width = indent - vim.fn.indent(outer_start),
  }

  return scope
end

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
      desc = '<motion> around the scope',
      function()
        local operator, count1 = vim.v.operator, vim.v.count1

        if not vim.list_contains({ 'd', 'c', 'y', 'g@' }, operator) then
          return
        end

        local win = vim.api.nvim_get_current_win()
        local buf = 0

        local row, col = table.unpack(vim.api.nvim_win_get_cursor(win))

        local scope = get_scope(buf, row, count1)

        if not scope then
          return
        end

        local indent_width = scope.indent_width

        local outer_start1, outer_end1 = scope.outer_start, scope.outer_end
        local inner_start1, inner_end1 = scope.inner_start, scope.inner_end

        local outer_start, outer_end = outer_start1 - 1, outer_end1 - 1
        local inner_start, inner_end = inner_start1 - 1, inner_end1 - 1

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
          local inner_lines
          if inner_start == inner_end then
            inner_lines = vim.api.nvim_buf_get_lines(buf, inner_start, inner_start + 1, false)
          else
            inner_lines = vim.api.nvim_buf_get_lines(buf, inner_start, inner_end + 1, false)
          end

          ---@param what 'outer'|'inner'
          ---@param with string[]
          local replace_scope = function(what, with)
            vim._with({ lockmarks = true }, function()
              if what == 'outer' then
                vim.api.nvim_buf_set_lines(buf, outer_start, outer_end + 1, false, with)
              end
              if what == 'inner' then
                vim.api.nvim_buf_set_lines(buf, inner_start, inner_end + 1, false, with)
              end
            end)
          end

          -- Dedent `inner_lines[]`
          for i, line in ipairs(inner_lines) do
            local line_indent = vim.fn.indent(inner_start + i)
            inner_lines[i] = vim.text.indent(line_indent - indent_width, line, { expandtab = 1 })
          end

          local cursor_dedent = {
            math.max(1, row - (inner_start - outer_start)),
            math.max(0, col - indent_width),
          }

          if operator == 'd' then
            replace_scope('outer', inner_lines)
            vim.api.nvim_win_set_cursor(win, cursor_dedent)
          end

          if operator == 'c' then
            local init_line = vim.api.nvim_buf_get_lines(buf, outer_start, outer_start + 1, false)[1]
            local padding = init_line:match '^%s*'
            replace_scope('outer', { padding, table.unpack(inner_lines) })
            vim.api.nvim_win_set_cursor(win, { inner_start, #padding })
          end

          if operator == 'g@' then
            require('vim._comment').toggle_lines(outer_start1, inner_start1 - 1)
            require('vim._comment').toggle_lines(inner_end1 + 1, outer_end1)
          end
        end, 150)
      end,
    },
  },
}
