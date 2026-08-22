local pack = require("util.pack")

pack.plug(function()
  local MiniStatuscolumn = require("mini.statuscolumn")

  MiniStatuscolumn.setup({
    content = MiniStatuscolumn.gen_content.main({
      { format = "s=l=", sep = "" },
      { ltype = "virt", lnum = "•" },
      { ltype = "wrap", lnum = "↳" },
    }),
  })
end)
