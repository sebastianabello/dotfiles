-- nvim-treesitter (rama main): compila parsers con el CLI `tree-sitter`
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    local langs = {
      "bash", "c", "css", "dockerfile", "go", "html", "javascript", "json",
      "lua", "markdown", "markdown_inline", "python", "rust", "toml",
      "tsx", "typescript", "vim", "vimdoc", "yaml",
    }
    ts.setup({})
    if vim.fn.executable("tree-sitter") == 1 then
      ts.install(langs)
    end
    -- Para instalaciones desatendidas: nvim --headless "+TSInstallAll" +qa
    vim.api.nvim_create_user_command("TSInstallAll", function()
      ts.install(langs):wait(300000)
    end, {})
    -- Activar resaltado de treesitter si hay parser para el tipo de archivo
    vim.api.nvim_create_autocmd("FileType", {
      callback = function() pcall(vim.treesitter.start) end,
    })
  end,
}
