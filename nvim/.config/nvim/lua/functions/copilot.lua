local M = {}

---Toggle the Copilot status for the current buffer.
function M.toggle()
  -- Check if the buffer has the variable set
  local success, copilot_status = pcall(vim.api.nvim_buf_get_var, 0, "copilot_enabled")

  -- If the variable is not set, then set it to true by default becase copilot's default state is on
  if not success then
    copilot_status = true
  end

  vim.api.nvim_buf_set_var(0, "copilot_enabled", not copilot_status)
end

return M
