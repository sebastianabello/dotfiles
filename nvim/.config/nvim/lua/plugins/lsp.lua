return {
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig", "saghen/blink.cmp" },
    config = function()
      -- Capacidades de completado para todos los servidores
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      -- mason-lspconfig habilita automáticamente los servidores instalados
      -- (stylua se excluye: ya lo ejecuta conform como formateador, no como LSP)
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "bashls", "pyright", "ts_ls", "jsonls" },
        automatic_enable = { exclude = { "stylua" } },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp", { clear = true }),
        callback = function(ev)
          local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
          end
          -- nvim 0.11+ ya trae: K, grn (renombrar), gra (acciones), grr (refs), gri (impl.)
          map("gd", vim.lsp.buf.definition, "Ir a definición")
          map("gD", vim.lsp.buf.declaration, "Ir a declaración")
          map("<leader>ca", vim.lsp.buf.code_action, "Acción de código")
          map("<leader>rn", vim.lsp.buf.rename, "Renombrar")
        end,
      })
    end,
  },
}
