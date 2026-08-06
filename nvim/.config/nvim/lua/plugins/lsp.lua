local lsp_funcs = require("functions.lsp")

return {
  "b0o/schemastore.nvim",
  "neovim/nvim-lspconfig",
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    config = function(_, opts)
      require("mason").setup(opts)
      lsp_funcs.mason_ensure_installed(opts.ensure_installed)
    end,
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        "checkstyle",
        "golangci-lint",
        "tflint",
        "stylua",
        "prettier",
        "taplo",
        "sqruff",
        "ruff",
        "oxlint",
        "oxfmt",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local schemastore = require("schemastore")

      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }

      vim.lsp.config("*", { capabilities = capabilities })
      vim.lsp.config("gopls", { settings = lsp_funcs.setup_gopls({}) })
      vim.lsp.config("jsonls", { settings = lsp_funcs.setup_jsonls({}, schemastore) })
      vim.lsp.config("yamlls", { settings = lsp_funcs.setup_yamlls({}, schemastore) })
      vim.lsp.config("helm_ls", { settings = lsp_funcs.setup_helm_ls() })

      require("mason-lspconfig").setup({
        automatic_enable = true,
        ensure_installed = {
          "biome",
          "buf_ls",
          "gopls",
          "helm_ls",
          "jdtls",
          "jsonls",
          "lua_ls",
          "rust_analyzer",
          "tailwindcss",
          "tofu_ls",
          "tsp_server",
          "ty",
          "vtsls",
          "yamlls",
        },
      })

      lsp_funcs.setup_sourcekit()
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on Lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load `luvit` types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = true,
  },
}
