-- Punto de entrada: opciones → keymaps → autocmds → plugins (lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
