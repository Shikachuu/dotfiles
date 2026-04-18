return {
  "coder/claudecode.nvim",
  config = true,
  lazy = true,
  opts = {
    terminal = {
      provider = "external",
      provider_opts = {
        external_terminal_cmd = vim.fn.has("mac") == 1 and function(cmd, env)
          local env_items = {}
          for k, v in pairs(env or {}) do
            table.insert(env_items, k .. "=" .. v)
          end
          local env_line = #env_items > 0
              and '  set environment variables of cfg to {"' .. table.concat(env_items, '", "') .. '"}\n'
            or ""

          local script = string.format(
            [=[
tell application "Ghostty"
  activate
  set cfg to new surface configuration
  set command of cfg to "bash -lc %s"
  set initial working directory of cfg to "%s"
%s  set t to new tab in front window with configuration cfg
end tell
]=],
            cmd:gsub('"', '\\"'),
            vim.fn.getcwd():gsub('"', '\\"'),
            env_line
          )

          local path = os.tmpname() .. ".scpt"
          local f = io.open(path, "w")
          if not f then
            return nil
          end
          f:write(script)
          f:close()

          return { "bash", "-c", "osascript " .. path .. " && sleep infinity" }
        end or "ghostty +new-window -e %s",
      },
    },
  },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
