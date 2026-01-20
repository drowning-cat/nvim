local pack = require("util.pack")

pack.later(function()
  vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("term_open", { clear = true }),
    desc = "Set options for the terminal window",
    callback = function()
      vim.wo.number = false
      vim.wo.relativenumber = false
    end,
  })

  vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

  vim.cmd.cnoreabbrev("Lz", "Lazygit")
  vim.api.nvim_create_user_command("Lazygit", function()
    vim.cmd.tabnew()
    vim.cmd.terminal("lazygit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      once = true,
      callback = function(e)
        vim.cmd.bwipeout({ args = { e.buf }, bang = true })
      end,
    })
    pcall(vim.cmd.file, "term:lazygit")
    vim.cmd.startinsert()
  end, {})

  vim.keymap.set("n", "<Leader>gg", "<Cmd>Lazygit<Enter>", { desc = "Lazygit" })
end)
