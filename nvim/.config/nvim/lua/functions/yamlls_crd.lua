local curl = require("plenary.curl")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")

local M = {
  schemas_catalog = "datreeio/CRDs-catalog",
  schema_catalog_branch = "main",
  github_headers = {
    Accept = "application/vnd.github+json",
    ["X-GitHub-Api-Version"] = "2022-11-28",
  },
}
M.schema_url = "https://raw.githubusercontent.com/" .. M.schemas_catalog .. "/" .. M.schema_catalog_branch

M.list_crds = function()
  local schema_descriptors_url = M.schema_url .. "/" .. "index.yaml"
  local response = curl.get(schema_descriptors_url, { headers = M.github_headers })
  local command = "echo '"
    .. vim.fn.escape(response.body, "'")
    .. '\' | yq \'[.[] | .[] | {"key": "\\(.kind) \\(.apiVersion)", "value": .filename}]\' -o=json'
  local yq_output = vim.fn.system(command)

  return vim.fn.json_decode(yq_output)
end

---Applys a helper line to the current buffer to set the schema for yamlls.
---@param schema_path string The path to the schema file in the catalog.
---@param buf number|nil The buffer number to apply the schema to. If not provided, uses the current buffer.
M.apply_schema = function(schema_path, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local schema_url = M.schema_url .. "/" .. schema_path
  local schema_modeline = "# yaml-language-server: $schema=" .. schema_url
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, { schema_modeline })
  vim.notify("Added schema modeline: " .. schema_modeline)
end

M.open_picker = function(opts)
  opts = opts or {}
  local trees = M.list_crds()
  local current_buf = vim.api.nvim_get_current_buf()

  local filetype = vim.bo[current_buf].filetype
  local valid_filetypes = {
    yaml = true,
    helm = true,
    kubernetes = true,
  }

  if not valid_filetypes[filetype] then
    vim.notify("This command is only valid for YAML, Helm, or Kubernetes files.", vim.log.levels.WARN)
    return
  end

  pickers
    .new(opts, {
      prompt_title = "Select YAML Schema",
      finder = finders.new_table({
        results = trees,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.key,
            ordinal = entry.key,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          if selection then
            M.apply_schema(selection.value, current_buf)
          end
          actions.close(prompt_bufnr)
        end)
        return true
      end,
    })
    :find()
end

return M
