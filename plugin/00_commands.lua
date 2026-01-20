vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update()
end, {})

vim.api.nvim_create_user_command("PackClean", function()
  local names = {}
  for _, p in ipairs(vim.pack.get()) do
    if not p.active then
      table.insert(names, p.spec.name)
    end
  end
  vim.pack.del(names)
end, {})
