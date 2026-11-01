local map = vim.keymap.set

-- Limpiar resaltado de búsqueda
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Guardar / salir
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Guardar" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Salir" })

-- Moverse entre ventanas
map("n", "<C-h>", "<C-w>h", { desc = "Ventana izquierda" })
map("n", "<C-j>", "<C-w>j", { desc = "Ventana abajo" })
map("n", "<C-k>", "<C-w>k", { desc = "Ventana arriba" })
map("n", "<C-l>", "<C-w>l", { desc = "Ventana derecha" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Buffer anterior" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Buffer siguiente" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Cerrar buffer" })

-- Mover líneas seleccionadas
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Mover abajo" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Mover arriba" })

-- Mantener selección al indentar
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Diagnósticos
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Ver diagnóstico" })
