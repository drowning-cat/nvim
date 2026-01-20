vim.keymap.set({ "n", "i" }, "<C-S-h>", "<Left>", { desc = "Cursor left" })
vim.keymap.set({ "n", "i" }, "<C-S-j>", "<Down>", { desc = "Cursor down" })
vim.keymap.set({ "n", "i" }, "<C-S-k>", "<Up>", { desc = "Cursor up" })
vim.keymap.set({ "n", "i" }, "<C-S-l>", "<Right>", { desc = "Cursor right" })

vim.keymap.set("i", "<S-Enter>", "<Enter><Up><End>", { desc = "Anchored enter" })

vim.keymap.set("n", "[p", '<Cmd>exe "put! " . v:register<Enter>', { desc = "Paste above" })
vim.keymap.set("n", "]p", '<Cmd>exe "put "  . v:register<Enter>', { desc = "Paste below" })

vim.keymap.set("o", "C", "gc", { remap = true, desc = "Close tab" })

vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<Enter>", { desc = "Clear hlsearch" })

vim.keymap.set("n", "gA", "<Cmd>tab split<Enter>", { desc = "Add tab" })
vim.keymap.set("n", "gC", "<Cmd>tabclose<Enter>", { desc = "Close tab" })

vim.keymap.set("n", "<C-w>Q", "<Cmd>qall<Enter>", { desc = "Quit" })

-- Swap buffers

local swap_buf = function(dir)
  assert(dir:match("[hjkl]"), "`dir` expected to be one of [hjkl]")
  local next_win, curr_win = vim.fn.win_getid(vim.fn.winnr(dir)), vim.api.nvim_get_current_win()
  local next_buf, curr_buf = vim.api.nvim_win_get_buf(next_win), vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_buf(next_win, curr_buf)
  vim.api.nvim_win_set_buf(curr_win, next_buf)
  vim.api.nvim_set_current_win(next_win)
end
-- stylua: ignore start
vim.keymap.set("n", "<C-w>mh", function() swap_buf("h") end, { desc = "Swap left" })
vim.keymap.set("n", "<C-w>mj", function() swap_buf("j") end, { desc = "Swap down" })
vim.keymap.set("n", "<C-w>mk", function() swap_buf("k") end, { desc = "Swap up" })
vim.keymap.set("n", "<C-w>ml", function() swap_buf("l") end, { desc = "Swap right" })
-- stylua: ignore end

-- Restart

local fallback_session = vim.fn.stdpath("state") .. "/Restart.vim"
local session_restart = function()
  local session = vim.v.this_session ~= "" and vim.v.this_session or fallback_session
  local esc_session = vim.fn.fnameescape(session)
  if vim.bo.buftype == "" then
    vim.cmd("silent! write")
  end
  vim.cmd(string.format("mksession! %s | confirm restart source %s", esc_session, esc_session))
end
-- stylua: ignore
vim.keymap.set("n", "<Leader>R", function() session_restart() end, { desc = "Restart" })

-- Copy to clipboard

vim.keymap.set("n", "gy", function()
  local copy = vim.fn.getreg('"')
  if copy == "" then
    return
  end
  vim.fn.setreg("+", copy)
  local msg = ""
  local _, ln = string.gsub(copy, "\n", "")
  if ln > 0 then
    msg = string.format('%d %s yanked into "+', ln, ln > 1 and "lines" or "line")
  else
    local ch = vim.fn.strdisplaywidth(copy)
    msg = string.format('%d %s yanked into "+', ch, ch > 1 and "chars" or "char")
  end
  vim.api.nvim_echo({ { msg } }, false, {})
end, { desc = "Yank last into clipboard" })

-- Quickfix toggle

local qf_height = { l = 10, c = 10 }
local toggle_list = function(nr)
  local mods = { split = "botright" }
  local type, win
  if nr then
    type, win = "l", vim.fn.getloclist(nr, { winid = true }).winid
  else
    type, win = "c", vim.fn.getqflist({ winid = true }).winid
  end
  if win > 0 then
    qf_height[type] = vim.api.nvim_win_get_height(win)
    vim.cmd({ cmd = type .. "close", mods = mods })
  else
    vim.cmd({ cmd = type .. "open" })
    vim.api.nvim_win_set_height(0, qf_height[type])
  end
end

-- stylua: ignore
vim.keymap.set("n", "<Leader>l", function() toggle_list() end, { desc = "Toggle qf" })
-- stylua: ignore
vim.keymap.set("n", "<Leader>L", function() toggle_list(0) end, { desc = "Toggle loc" })

-- Gh browse

local gh_browse = function()
  local git_root = assert(vim.fs.root(0, ".git"), "No git repository")
  local buf_name = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= "" or buf_name == "" then
    error("No file")
  end
  local git_path = assert(vim.fs.relpath(git_root, buf_name), "No relpath")
  local target = git_path
  if vim.v.count > 0 then
    target = git_path .. ":" .. vim.v.count1
  end
  local cmd = { "gh", "browse", target }
  local on_exit = function(out)
    if out.code == 0 then
      vim.notify(string.format('Opening "%s"', table.concat(cmd, " ")))
    elseif out.stderr ~= "" then
      vim.notify(out.stderr, vim.log.levels.ERROR)
    end
  end
  vim.system(cmd, { cwd = git_root }, vim.schedule_wrap(on_exit))
end

-- stylua: ignore
vim.keymap.set({ "n", "x" }, "<Leader>gB", function() gh_browse() end, { desc = "Gh browse" })
