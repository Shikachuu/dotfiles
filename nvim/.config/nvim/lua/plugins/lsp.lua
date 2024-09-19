return {
  "b0o/schemastore.nvim",
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
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
        if server == "gopls" then
          settings = {
            gopls = {
              analyses = {
                useany = true,
                unusedvariable = true,
              },
              staticcheck = true,
            },
          }
        end

        if server == "jsonls" then
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          }
        end

        if server == "yamlls" then
          settings = {
            yaml = {
              schemaStore = {
                -- disable the built-in schemaStore support
                enable = false,
                -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                url = "",
              },
              schemas = require("schemastore").yaml.schemas(),
              validate = true,
            },
          }
        end

        require("lspconfig")[server].setup({
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
        ensure_installed = {
          "gopls",
          "lua_ls",
          "jsonls",
          "yamlls",
          "sqls",
          "vtsls",
          "terraformls",
          "vacuum",
        },
        handlers = { default_setup },
      })
    end,
  },
  "neovim/nvim-lspconfig",
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
