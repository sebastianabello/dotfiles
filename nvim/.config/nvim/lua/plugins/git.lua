return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(buf)
      local gs = require("gitsigns")
      local function map(k, f, d)
        vim.keymap.set("n", k, f, { buffer = buf, desc = "Git: " .. d })
      end
      map("]h", function()
        gs.nav_hunk("next")
      end, "Siguiente hunk")
      map("[h", function()
        gs.nav_hunk("prev")
      end, "Hunk anterior")
      map("<leader>hp", gs.preview_hunk, "Previsualizar hunk")
      map("<leader>hb", gs.blame_line, "Blame de línea")
    end,
  },
}
