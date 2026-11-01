-- nvim-treesitter (rama main): compila parsers con el CLI `tree-sitter`
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup({})
    if vim.fn.executable("tree-sitter") == 1 then
      ts.install({
        "bash", "c", "css", "dockerfile", "go", "html", "javascript", "json",
        "lua", "markdown", "markdown_inline", "python", "rust", "toml",
        "tsx", "typescript", "vim", "vimdoc", "yaml",
      })
    end
    -- Activar resaltado de treesitter si hay parser para el tipo de archivo
    vim.api.nvim_create_autocmd("FileType", {
      callback = function() pcall(vim.treesitter.start) end,
    })
  end,
}
