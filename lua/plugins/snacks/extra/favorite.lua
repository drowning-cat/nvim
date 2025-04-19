---@module 'snacks'

---@class Favorite
---@field letter string
---@field file string

---@class FavoriteItem : snacks.picker.Item, Favorite

---@class FavoriteConfig
---@field letters? string
---@field ctx_markers? string[]
---@field map_letters? fun(letter: string)

local M = {}
-- stylua: ignore
setmetatable(M, { __call = function(...) M.pick_favorite(...) end })

---@type FavoriteConfig
M.config = {
  letters = '1234567890',
  ctx_markers = { '.git', '_darcs', '.hg', '.bzr', '.svn', 'package.json', 'Makefile' },
  map_letters = function() end,
}

M._did_setup = false

---@param opts? FavoriteConfig
M.setup = function(opts)
  if M._did_setup then
    return
  end
  M._did_setup = true
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  vim.cmd.rshada()
  vim.g.FAVORITES = (vim.g.FAVORITES or {}) ---@type table<string, Favorite[]>
  vim.iter(vim.split(M.config.letters, '')):each(M.config.map_letters)
  return M
end

M.util = {}

---@param buf? number
M.util.find_ctx = function(buf)
  buf = buf or 0
  local markers = M.config.ctx_markers or {}
  local mark = vim.fs.find(markers, { upward = true, type = 'directory' })[1]
  return vim.fs.dirname(mark) or 'unknown'
end

M.store = {}

---@return string[]
M.store.get_ctx_list = function()
  -- stylua: ignore
  return vim.iter(vim.g.FAVORITES):filter(function(_, val) return #val > 0 end):map(function(key) return key end):totable()
end

---@param ctx string|nil
M.store.get_favorites = function(ctx)
  ctx = ctx or M.util.find_ctx()
  vim.cmd.rshada()
  vim.g.FAVORITES = vim.g.FAVORITES or {}
  return vim.g.FAVORITES[ctx] or {}
end

---@param ctx string|nil
---@param items Favorite[]
M.store.set_favorites = function(ctx, items)
  ctx = ctx or M.util.find_ctx()
  -- vim.g.FAVORITES is immutable, make sure to assign a new value
  vim.g.FAVORITES = vim.tbl_extend('force', vim.g.FAVORITES or {}, {
    [ctx] = items,
  })
  vim.cmd.wshada()
  return items
end

---@param ctx string|nil
M.store.wipe_favorites = function(ctx)
  ctx = ctx or M.util.find_ctx()
  local favs = vim.g.FAVORITES or {}
  favs[ctx] = nil
  vim.g.FAVORITES = favs
  vim.cmd.wshada()
end

---@param ctx string|nil
---@param find {file:string}|{letter:string}
M.store.find_favorite = function(ctx, find)
  return vim.iter(M.store.get_favorites(ctx)):find(function(fav)
    return fav.file == find.file or fav.letter == find.letter
  end)
end

---@param ctx string|nil
---@param file string
M.store.insert_favorite = function(ctx, file)
  local fav_list = M.store.get_favorites(ctx)
  local letter = vim.split(M.config.letters, '')[#fav_list + 1]
  if not letter then
    Snacks.notify.error 'Letters exceeded'
    return
  end
  local found = vim.iter(fav_list):find(function(fav)
    return fav.file == file
  end)
  if not found then
    local favorite = { ---@type Favorite
      file = file,
      letter = letter,
    }
    table.insert(fav_list, favorite)
    M.store.set_favorites(ctx, fav_list)
    return favorite
  end
end

---@param ctx string|nil
---@param find {file:string}|{letter:string}
M.store.remove_favorite = function(ctx, find)
  ctx = ctx or M.util.find_ctx()
  local fav_list = M.store.get_favorites(ctx)
  local removed, rest = {}, {}
  for _, fav in ipairs(fav_list) do
    if fav.file == find.file or fav.letter == find.letter then
      table.insert(removed, fav)
    else
      table.insert(rest, fav)
    end
  end
  if #rest == 0 then
    M.store.wipe_favorites(ctx)
  else
    M.store.set_favorites(ctx, rest)
  end
  return removed
end

---@param ctx string|nil
---@param find {file:string}|{letter:string}
---@param to {file?:string,letter?:string}
M.store.change_favorite = function(ctx, find, to)
  local fav_list = M.store.get_favorites(ctx)
  for i, fav in ipairs(fav_list) do
    if fav.file == find.file or fav.letter == find.letter then
      local new = vim.tbl_extend('force', fav, to)
      -- Optional: error if the changed letter is not in M.config.letters
      -- if not string.find(M.config.letters, new.letter) then
      --   Snacks.notify.error 'Unknown letter'
      --   return
      -- end
      fav_list[i] = new -- mutate
      M.store.set_favorites(ctx, fav_list)
      return fav
    end
  end
end

---@param ctx string|nil
M.store.reletter_all = function(ctx)
  local fav_list = M.store.get_favorites(ctx)
  for i, fav in ipairs(fav_list) do
    fav.letter = vim.split(M.config.letters, '')[i]
  end
  return M.store.set_favorites(ctx, fav_list)
end

M.api = {}

---@param opts? {ctx?:string,buf?:number}
M.api.add_buf = function(opts)
  opts = opts or {}
  local file = vim.api.nvim_buf_get_name(opts.buf or 0)
  if file ~= '' then
    return M.store.insert_favorite(opts.ctx, file)
  end
end

---@param opts? {ctx?:string,buf?:number}
M.api.remove_buf = function(opts)
  opts = opts or {}
  local file = vim.api.nvim_buf_get_name(opts.buf or 0)
  if file ~= '' then
    return M.store.remove_favorite(opts.ctx, { file = file })
  end
end

---@param opts {ctx?:string,file:string}|{ctx?:string,letter:string}
M.api.jump = function(opts)
  local fav_list = M.store.get_favorites(opts.ctx)
  local fav = vim.iter(fav_list):find(function(fav)
    return fav.letter == opts.letter or fav.file == opts.file
  end)
  if fav then
    vim.cmd.edit(fav.file)
    return fav
  end
end

---@param opts? snacks.picker.Config
M.pick_favorite = function(opts)
  opts = opts or {}
  local fast_keys = {}
  for _, letter in ipairs(vim.split(M.config.letters, '')) do
    fast_keys[letter] = {
      function(picker) ---@param picker snacks.Picker
        picker:close()
        vim.schedule(function()
          M.api.jump { letter = letter }
        end)
      end,
      mode = { 'i', 'n' },
    }
  end
  local ctx = M.util.find_ctx() ---@type string?
  ---@param dir 1|-1
  local cycle_ctx = function(dir)
    ---@param picker snacks.Picker
    return function(picker)
      local list = M.store.get_ctx_list()
      local idx, max = 1, #list
      for i, c in ipairs(list) do
        -- stylua: ignore
        if c == ctx then idx = i; break end
      end
      for i, c in ipairs(list) do
        if c == ctx then
          if dir == -1 then
            ctx = list[i - 1] or list[#list]
          else
            ctx = list[i + 1] or list[1]
          end
          idx = idx < max and idx + 1 or 1
          picker.title = string.format('Select [%d/%d]', idx, max)
          picker:find()
          return
        end
      end
      ctx = nil
    end
  end
  local items_len = #M.store.get_favorites()
  return Snacks.picker.pick(vim.tbl_deep_extend('keep', opts, {
    layout = {
      preset = 'select',
      layout = {
        height = math.floor(math.min(vim.o.lines * 0.8 - 10, items_len + 3) + 0.5),
        min_height = 10,
        max_width = 60,
      },
    },
    ---@param item FavoriteItem
    format = function(item, picker)
      local ret = {} ---@type snacks.picker.Highlight[]
      table.insert(ret, { item.letter, 'SnacksPickerIdx' })
      table.insert(ret, { '  ' })
      vim.list_extend(ret, Snacks.picker.format.filename(item, picker))
      return ret
    end,
    finder = function()
      local favorites = M.store.get_favorites(ctx)
      local items = {} ---@type FavoriteItem[]
      for i, fav in ipairs(favorites) do
        table.insert(items, {
          idx = i,
          file = fav.file,
          letter = fav.letter,
          item = fav,
          text = fav.letter .. ' ' .. fav.file, -- Search string
        })
      end
      return items
    end,
    actions = {
      fav_next_ctx = cycle_ctx(1),
      fav_prev_ctx = cycle_ctx(-1),
      fav_del = function(picker, item)
        local delete = picker:selected { fallback = true }
        for _, it in ipairs(delete) do
          M.store.remove_favorite(ctx, { file = it.file })
        end
        if picker:count() == 0 then
          picker:close()
        else
          picker.list:set_selected()
          picker.list:set_target(math.min(picker.list.cursor, picker:count() - #delete))
          picker:find()
        end
      end,
      fav_reletter = function(picker, item)
        Snacks.input.input({ default = item.letter }, function(letter)
          M.store.change_favorite(ctx, { file = item.file }, { letter = letter })
          picker.list:set_selected()
          picker.list:set_target()
          picker:find()
        end)
      end,
      fav_reletter_all = function(picker)
        M.store.reletter_all(ctx)
        picker.list:set_selected()
        picker.list:set_target()
        picker:find()
      end,
    },
    win = {
      input = {
        keys = vim.tbl_extend('force', fast_keys, {
          ['<Right>'] = { 'fav_next_ctx', mode = { 'i', 'n' } },
          ['<Left>'] = { 'fav_prev_ctx', mode = { 'i', 'n' } },
          ['<C-r>'] = { 'fav_reletter', mode = { 'i', 'n' } },
          ['<C-d>'] = { 'fav_del', mode = { 'i', 'n' } },
          ['d'] = 'fav_del',
          ['r'] = 'fav_reletter',
          ['R'] = 'fav_reletter_all',
        }),
      },
    },
  } --[[@as snacks.picker.Config]]))
end

return M
