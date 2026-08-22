-- See https://github.com/folke/snacks.nvim/blob/882c996cf28183f4d63640de0b4c02ec886d01f2/lua/snacks/bigfile.lua
local au_bigfile = vim.api.nvim_create_augroup("config/bigfile", { clear = true })

local bigfile_size = 0.5 * 1024 * 1024 -- MiB
local bigfile_line_length = 1000

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
        if size > bigfile_size then
          return "bigfile"
        end
        local line_count = vim.api.nvim_buf_line_count(buf)
        if line_count < 1 then
          return
        end
        local avg_line_length = (size - line_count) / line_count
        if avg_line_length > bigfile_line_length then
          return "bigfile"
        end
      end,
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "bigfile",
  group = au_bigfile,
  desc = "Disable expensive features for `bigfile`",
  callback = function(e)
    local buf = e.buf
    local ft = vim.filetype.match({ buf = buf }) or ""
    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p:~:.")
    vim.notify(string.format("Big file detected `%s`. Some features disabled.", path), vim.log.levels.WARN)
    vim.api.nvim_buf_call(buf, function()
      if vim.fn.exists(":NoMatchParen") ~= 0 then
        vim.cmd("NoMatchParen")
      end
      local formatters = vim.g.formatters or {}
      vim.g.formatconf = vim.tbl_extend("force", vim.g.formatconf or {}, {
        bigfile = formatters[ft],
      })
      vim.g.format_on_save = false
      vim.b.completion = false
      vim.b.minianimate_disable = true
      vim.b.minihipatterns_disable = true
      vim.bo.indentexpr = ""
      vim.wo.foldmethod = "manual"
      vim.wo.statuscolumn = ""
      vim.wo.conceallevel = 0
      vim.diagnostic.enable(false, { bufnr = buf })
      -- NOTE: Restore syntax highlighting after FileType finishes
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.bo[buf].syntax = ft
        end
      end)
    end)
  end,
})
