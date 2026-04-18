local M = {}

-- Stack tracking the chain of selected nodes for incremental selection.
-- Reset on init_selection, pushed on expand, popped on shrink.
M._selection_stack = {}

-- Visually select the range of a treesitter node.
local function select_node(node)
  local sr, sc, er, ec = node:range()
  vim.api.nvim_buf_set_mark(0, "<", sr + 1, sc, {})
  vim.api.nvim_buf_set_mark(0, ">", er + 1, ec > 0 and ec - 1 or 0, {})
  vim.cmd("normal! gv")
end

-- Start visual selection on the treesitter node under the cursor.
M.init_selection = function()
  local node = vim.treesitter.get_node()
  if not node then return end
  M._selection_stack = { node }
  select_node(node)
end

-- Expand the current selection to the parent node.
M.node_incremental = function()
  local node = M._selection_stack[#M._selection_stack]
  if not node then return end
  local parent = node:parent()
  if not parent then return end
  table.insert(M._selection_stack, parent)
  select_node(parent)
end

-- Expand the current selection to the next named ancestor (scope-like).
M.scope_incremental = function()
  local node = M._selection_stack[#M._selection_stack]
  if not node then return end
  local parent = node:parent()
  while parent and not parent:named() do
    parent = parent:parent()
  end
  if not parent then return end
  table.insert(M._selection_stack, parent)
  select_node(parent)
end

-- Shrink the selection back to the previous node in the stack.
M.node_decremental = function()
  if #M._selection_stack <= 1 then return end
  table.remove(M._selection_stack)
  select_node(M._selection_stack[#M._selection_stack])
end

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

M.setup_starlark = function()
  vim.filetype.add({
    pattern = {
      ["Tiltfile"] = "starlark",
    },
  })
end

return M
