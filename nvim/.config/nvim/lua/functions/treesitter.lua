local M = {}

M.setup_gotmpl = function()
  vim.filetype.add({
    extension = {
      gotmpl = "gotmpl",
    },
    pattern = {
      [".*/templates/.*%.tpl"] = "helm",
      [".*/templates/.*%.ya?ml"] = "helm",
      ["helmfile.*%.ya?ml"] = "helm",
    },
  })
end

return M
