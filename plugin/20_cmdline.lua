local setcmdpos = function(pos, next_pos)
  local move = next_pos - pos
  local keys = string.rep(move >= 0 and "<Right>" or "<Left>", math.abs(move))
  vim.api.nvim_input(keys)
end

-- NOTE(cmdline): Jump `word` like in Insert mode

local regex_word_left = vim.regex([=[\([^[:keyword:][:space:]]\+\|\k\+\)\s*$]=])
local regex_word_right = vim.regex([=[^\([^[:keyword:][:space:]]\+\|\k\+\)\s*]=])

vim.keymap.set("c", "<C-Left>", function()
  local cmdline, pos = vim.fn.getcmdline(), vim.fn.getcmdpos()
  local from, _ = regex_word_left:match_str(cmdline:sub(1, pos - 1))
  setcmdpos(pos, from and from + 1 or 1)
end, {})

vim.keymap.set("c", "<C-Right>", function()
  local cmdline, pos = vim.fn.getcmdline(), vim.fn.getcmdpos()
  local _, to = regex_word_right:match_str(cmdline:sub(pos))
  setcmdpos(pos, to and to + pos or #cmdline + 1)
end, {})

-- FIX(cmdline): Skip consecutive spaces between `WORD`

vim.keymap.set("c", "<S-Left>", function()
  local cmdline, pos = vim.fn.getcmdline(), vim.fn.getcmdpos()
  local word_start = cmdline:sub(1, pos - 1):find("%S+%s*$")
  setcmdpos(pos, word_start or 1)
end, {})

vim.keymap.set("c", "<S-Right>", function()
  local cmdline, pos = vim.fn.getcmdline(), vim.fn.getcmdpos()
  local word_end = cmdline:find("%f[%S]", pos + 1)
  setcmdpos(pos, word_end or #cmdline + 1)
end, {})

-- NOTE(insert): Jump `WORD`

vim.keymap.set("i", "<S-Left>", "<Cmd>norm! B<CR>", {})
vim.keymap.set("i", "<S-Right>", "<Cmd>norm! W<CR>", {})
