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
        "golangci-lint",
        "stylua",
        "prettier",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
      lsp_capabilities.textDocument.foldingRandge = { dynamicRegistration = true }
      local settings = {}
      local default_setup = function(server)
        local schemastore = require("schemastore")
        local lspconfig = require("lspconfig")

        if server == "gopls" then
          settings = lsp_funcs.setup_gopls(settings)
        elseif server == "jsonls" then
          settings = lsp_funcs.setup_jsonls(settings, schemastore)
        elseif server == "yamlls" then
          settings = lsp_funcs.setup_yamlls(settings, schemastore)
        elseif server == "helm_ls" then
          settings = lsp_funcs.setup_helm_ls()
        end

        lspconfig[server].setup({
          capabilities = lsp_capabilities,
          settings = settings,

          handlers = {
            ["textDocument/foldingRange"] = function(_, _, result)
              if not result then
                return
              end
              vim.lsp.util.set_fold(result)
            end,
          },
        })
      end

      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = {
          "biome",
          "gopls",
          "helm_ls",
          "jsonls",
          "lua_ls",
          "rust_analyzer",
          "sqls",
          "tailwindcss",
          "terraformls",
          "vacuum",
          "vtsls",
          "yamlls",
        },
        handlers = { default_setup },
      })
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
