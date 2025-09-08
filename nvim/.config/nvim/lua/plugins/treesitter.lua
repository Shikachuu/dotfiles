return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  priority = 10,
  config = function()
    require("nvim-treesitter.configs").setup({
      build = ":TSUpdate",
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
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
      sync_install = true,
      auto_install = true,
      highlight = {
        -- `false` will disable the whole extension
        enable = true,
      },
      ignore_install = {},
      modules = {},
      autotag = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>", -- set to `false` to disable one of the mappings
          node_incremental = "<CR>",
          scope_incremental = "<TAB>",
          node_decremental = "<S-TAB>",
        },
      },
    })

    local ts_functions = require("functions.treesitter")

    ts_functions.setup_gotmpl()
  end,
}
