return {
  "nvim-telescope/telescope.nvim",
  branch = "master",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Buscar archivos" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Buscar texto (rg)" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Ayuda" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Archivos recientes" },
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnósticos" },
  },
  config = function()
    require("telescope").setup({})
    pcall(require("telescope").load_extension, "fzf")
  end,
}
