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
