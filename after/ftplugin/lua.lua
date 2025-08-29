if vim then
  vim.b.minisurround_config = {
    custom_surroundings = {
      l = { output = { left = "vim.print({ ", right = " })" } },
    },
  }
end
