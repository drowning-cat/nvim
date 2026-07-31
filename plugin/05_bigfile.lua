-- See https://github.com/folke/snacks.nvim/blob/882c996cf28183f4d63640de0b4c02ec886d01f2/lua/snacks/bigfile.lua

local max_size = 1.5 * 1024 * 1024 -- 1.5 MiB
local line_length = 1000

---@param ctx { buf: number, ft: string }
local on_bigfile = function(ctx)
  if vim.fn.exists(":NoMatchParen") ~= 0 then
    vim.cmd("NoMatchParen")
  end
  vim.b.completion = false
  vim.b.minianimate_disable = true
  vim.b.minihipatterns_disable = true
  vim.wo.foldmethod = "manual"
  vim.wo.statuscolumn = ""
  vim.wo.conceallevel = 0
  -- NOTE: Restore syntax highlighting after FileType finishes
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(ctx.buf) then
      vim.bo[ctx.buf].syntax = ctx.ft
    end
  end)
end

vim.filetype.add({
  pattern = {
    [".*"] = {
      function(path, buf)
        if not path or not buf or vim.bo[buf].filetype == "bigfile" then
          return
        end
        if path ~= vim.fs.normalize(vim.api.nvim_buf_get_name(buf)) then
          return
        end
        local size = vim.fn.getfsize(path)
        if size <= 0 then
          return
        end
        if size > max_size then
          return "bigfile"
        end
        local lines = vim.api.nvim_buf_line_count(buf)
        return (size - lines) / lines > line_length and "bigfile" or nil
      end,
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("bigfile", { clear = true }),
  pattern = "bigfile",
  desc = "Disable expensive features for `bigfile`",
  callback = function(e)
    local buf = e.buf
    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p:~:.")
    vim.notify(string.format("Big file detected `%s`. Some features disabled.", path), vim.log.levels.WARN)
    vim.api.nvim_buf_call(buf, function()
      local ft = vim.filetype.match({ buf = buf }) or ""
      on_bigfile({ buf = buf, ft = ft })
    end)
  end,
})
