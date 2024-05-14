return {
  'nvim-treesitter/nvim-treesitter',
  tag = 'v0.9.2',
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter.configs').setup {
      build = ':TSUpdate',
      ensure_installed = {
        "markdown",
        "vim",
        "vimdoc",
        "bash",
        "lua",
        "go",
        "gomod",
        "gosum",
        "proto",
        "dockerfile",
        "javascript",
        "typescript",
        "html",
        "json",
        "yaml",
        "sql",
      },
      sync_install = true,
      auto_install = true,
      highlight = {
        -- `false` will disable the whole extension
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>", -- set to `false` to disable one of the mappings
          node_incremental = "<CR>",
          scope_incremental = "<TAB>",
          node_decremental = "<S-TAB>",
        }
      }
    }
  end,
}
-- vim: ts=2 sts=2 sw=2 et
