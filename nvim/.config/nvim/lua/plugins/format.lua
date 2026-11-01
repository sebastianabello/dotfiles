return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        python = { "ruff_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
      },
      format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
    },
  },
  {
    -- Instala formateadores vía mason
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = { ensure_installed = { "stylua", "shfmt", "prettier", "ruff", "tree-sitter-cli" } },
  },
}
