local M = {}

vim.g.root_markers = vim.F.if_nil(vim.g.root_markers, {})
vim.g.project_ignore = vim.F.if_nil(vim.g.project_ignore, {})

function M.setup()
  vim.g.cwd_glob = vim.fn.getcwd()
  vim.g.cwd_auto = vim.fn.getcwd()

  vim.api.nvim_create_autocmd("DirChangedPre", {
    group = vim.api.nvim_create_augroup("find_root", { clear = true }),
    callback = function(e)
      if e.match == "global" then
        vim.g.cwd_glob = e.file
      end
      if e.match == "auto" then
        vim.g.cwd_auto = e.file
      end
    end,
  })
end

function M.find_root(source)
  source = source or vim.g.cwd_glob or vim.fn.getcwd()
  local root = vim.fs.root(source, vim.g.root_markers or {})
  if not root or root == vim.fs.normalize("~") then
    return nil
  end
  return root
end

function M.find_projects(dirs, max_depth, nested)
  dirs = vim.tbl_map(vim.fs.abspath, dirs or {})
  max_depth = max_depth and max_depth + 1 or 5
  nested = nested == nil and false or true
  local project_dirs = {}
  local parse_path = function(root_dir, fs_name)
    local path = vim.fs.abspath(vim.fs.joinpath(root_dir, fs_name))
    local basename, dirname = vim.fs.basename(path), vim.fs.dirname(path)
    return path, basename, dirname
  end
  local dir_skip = function(root_dir)
    return function(dir_name)
      local _, basename, dirname = parse_path(root_dir, dir_name)
      local ignore = vim.list_contains(vim.g.project_ignore or {}, basename)
      return not ((nested and project_dirs[dirname]) or ignore)
    end
  end
  for _, root_dir in ipairs(dirs) do
    for name, _ in vim.fs.dir(root_dir, { depth = max_depth, skip = dir_skip(root_dir) }) do
      local _, basename, dirname = parse_path(root_dir, name)
      if vim.list_contains(vim.g.root_markers or {}, basename) then
        project_dirs[dirname] = root_dir
      end
    end
  end
  local items = {}
  for project_dir, root_dir in pairs(project_dirs) do
    table.insert(items, { path = project_dir, root = root_dir })
  end
  return items
end

return M
