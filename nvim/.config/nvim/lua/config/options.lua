local o = vim.opt

o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.scrolloff = 8
o.wrap = false
o.termguicolors = true
o.showmode = false -- lo muestra lualine
o.splitright = true
o.splitbelow = true
o.laststatus = 3

-- Indentación
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true

-- Búsqueda
o.ignorecase = true
o.smartcase = true
o.inccommand = "split"

-- Sistema
o.clipboard = "unnamedplus"
o.undofile = true
o.updatetime = 250
o.timeoutlen = 400
o.mouse = "a"
o.completeopt = "menu,menuone,noselect"

vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  severity_sort = true,
  float = { border = "rounded" },
})
