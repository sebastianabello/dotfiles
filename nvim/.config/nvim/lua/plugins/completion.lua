return {
  "saghen/blink.cmp",
  version = "1.*", -- binarios precompilados
  opts = {
    keymap = { preset = "default" }, -- <C-y> aceptar, <C-space> abrir, <C-e> cerrar
    appearance = { nerd_font_variant = "mono" },
    completion = { documentation = { auto_show = true } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
  },
}
