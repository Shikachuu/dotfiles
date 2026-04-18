return {
  "romus204/tree-sitter-manager.nvim",
  lazy = false,
  priority = 10,
  config = function()
    require("tree-sitter-manager").setup({
      ensure_installed = {
        "bash",
        "caddy",
        "css",
        "dockerfile",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "gotmpl",
        "gosum",
        "hcl",
        "html",
        "helm",
        "javascript",
        "json",
        "just",
        "lua",
        "make",
        "markdown",
        "proto",
        "rust",
        "sql",
        "starlark",
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
      sync_install = true,
      auto_install = true,
      highlight = true,
    })

    local ts_functions = require("functions.treesitter")

    ts_functions.setup_gotmpl()
  end,
}
