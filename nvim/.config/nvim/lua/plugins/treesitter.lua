return {
  "romus204/tree-sitter-manager.nvim",
  lazy = false,
  priority = 10,
  config = function()
    require("tree-sitter-manager").setup({
      languages = {
        dotprompt = {
          install_info = {
            url = "https://github.com/google/dotprompt",
            branch = "main",
            location = "packages/treesitter",
            queries = "queries",
          },
        },
      },
      ensure_installed = {
        "bash",
        "caddy",
        "css",
        "dockerfile",
        "dotprompt",
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
        "swift",
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
    ts_functions.setup_starlark()
    ts_functions.setup_dotprompt()
  end,
}
