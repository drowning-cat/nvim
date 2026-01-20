local M = {}

local ok, ts_repeat = pcall(require, "nvim-treesitter-textobjects.repeatable_move")

M.ok = ok

---@param opts { forward: boolean, func: fun(isf: boolean) }
function M.save_last(opts)
  if not M.ok then
    return
  end
  opts = vim.tbl_extend("keep", opts, {
    forward = true,
    func = function(_) end,
  })
  ts_repeat.last_move = {
    func = function(func_opts)
      return opts.func(func_opts.forward)
    end,
    opts = { forward = opts.forward },
    additional_args = {},
  }
end

return M
