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
setmetatable(M, { __call = function(...) M.view.favorite(...) end })

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
  return vim.iter(vim.g.FAVORITES):map(function(key) return key end):totable()
end

---@param ctx? string
M.store.get_ctx_index = function(ctx)
  ctx = ctx or M.util.find_ctx()
  local ctx_list = M.store.get_ctx_list()
  for i, c in ipairs(ctx_list) do
    if c == ctx then
      return i, #ctx_list
    end
  end
  return nil, #ctx_list
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
  local fav_list = M.store.get_favorites(ctx)
  local filtered, removed = {}, {}
  for _, fav in ipairs(fav_list) do
    if fav.file == find.file or fav.letter == find.letter then
      table.insert(removed, fav)
    else
      table.insert(filtered, fav)
    end
  end
  M.store.set_favorites(ctx, filtered)
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

M.view = {}

---@param opts? snacks.picker.Config
M.view.picker_favorites = function(opts)
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
  local ctx_current = nil
  ---@param dir 1|-1
  local cycle_ctx = function(dir)
    ---@param picker snacks.Picker
    return function(picker)
      local list = M.store.get_ctx_list()
      local find = ctx_current or M.util.find_ctx()
      for i, ctx in ipairs(list) do
        if ctx == find then
          if dir == -1 then
            ctx_current = list[i - 1] or list[#list]
            picker:find()
          else
            ctx_current = list[i + 1] or list[1]
            picker:find()
          end
          return
        end
      end
      ctx_current = nil
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
    on_show = function(picker)
      local _, max = M.store.get_ctx_index()
      local index = 1
      local update_titles = picker.update_titles
      picker.update_titles = function(self)
        index = index < max and index + 1 or 1
        picker.title = string.format('Select [%d/%d]', index, max)
        update_titles(self)
      end
    end,
    ---@param item FavoriteItem
    format = function(item, picker)
      local ret = {} ---@type snacks.picker.Highlight[]
      table.insert(ret, { item.letter, 'SnacksPickerIdx' })
      table.insert(ret, { '  ' })
      vim.list_extend(ret, Snacks.picker.format.filename(item, picker))
      return ret
    end,
    finder = function()
      local favorites = M.store.get_favorites(ctx_current)
      local items = {} ---@type FavoriteItem[]
      for _, fav in ipairs(favorites) do
        table.insert(items, {
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
        M.store.remove_favorite(nil, { file = item.file })
        picker:find()
      end,
      fav_reletter = function(picker, item)
        Snacks.input.input({ default = item.letter }, function(letter)
          M.store.change_favorite(nil, { file = item.file }, { letter = letter })
          picker:find()
        end)
      end,
      fav_reletter_all = function(picker)
        M.store.reletter_all(nil)
        picker:find()
      end,
    },
    win = {
      input = {
        keys = vim.tbl_extend('force', fast_keys, {
          ['<C-h>'] = { 'fav_prev_ctx', mode = { 'i', 'n' } },
          ['<C-l>'] = { 'fav_next_ctx', mode = { 'i', 'n' } },
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
