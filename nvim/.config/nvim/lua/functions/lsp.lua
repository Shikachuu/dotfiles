local M = {}

---This function is called when setting up the gopls language server
---@param settings table The settings table to be modified
---@return table
M.setup_gopls = function(settings)
  settings.gopls = {
    analyses = {
      useany = true,
      unusedvariable = true,
    },
    staticcheck = true,
  }
  return settings
end

---This function is called when setting up the json language server
---It configures the server to use the schema store for schema validation
---@param settings table The settings table to be modified
---@return table
M.setup_jsonls = function(settings, schemastore)
  settings.json = {
    schemas = schemastore.json.schemas(),
    validate = { enable = true },
  }
  return settings
end

---This function is called when setting up the yaml language server
---It configures the server to use the schema store for schema validation
---@param settings table The settings table to be modified
---@return table
M.setup_yamlls = function(settings, schemastore)
  settings.yaml = {
    schemaStore = {
      -- disable the built-in schemaStore support
      enable = false,
      -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
      url = "",
    },
    schemas = schemastore.yaml.schemas(),
    validate = true,
  }
  return settings
end

---This function is called when setting up the helm language server
---It configures the language server to use the yaml language server
---@return table
M.setup_helm_ls = function()
  return {
    ["helm-ls"] = {
      yamlls = {
        path = "yaml-language-server",
      },
    },
  }
end

---Registers sourcekit-lsp, which mason cannot install.
---nvim-lspconfig ships lsp/sourcekit.lua, so this only overrides the filetypes
---and root resolution. Attaches only when the binary exists and the project is a
---Swift package, leaving machines without a toolchain unaffected.
M.setup_sourcekit = function()
  vim.lsp.config("sourcekit", {
    filetypes = { "swift" },
    root_dir = function(bufnr, on_dir)
      if vim.fn.executable("sourcekit-lsp") == 0 then
        return
      end

      local root = vim.fs.root(bufnr, { "Package.swift", ".sourcekit-lsp" })
      if root then
        on_dir(root)
      end
    end,
  })

  vim.lsp.enable("sourcekit")
end

---This function ensures that the specified linters are installed using Mason
---@param linters table List of linters to ensure are installed
M.mason_ensure_installed = function(linters)
  local mr = require("mason-registry")

  local function ensure_installed()
    for _, tool in ipairs(linters) do
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
end

return M
