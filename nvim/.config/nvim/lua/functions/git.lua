local api = vim.api
local Job = require("plenary.job")

local M = {}

-- Default preprompt for Claude Code commit message generation
local default_preprompt = [[
  Generate a concise, conventional commit message for these changes.
  The lines should be wrapped at 72 chars and use 50 chars for the title.
  Use conventional commits format (feat:, fix:, docs:, etc.).
  Be specific about what changed and why, but not too verbose.
  This command's output is being piped, please ONLY output the commit message.
]]

local function get_all_git_changes(callback)
  Job:new({
    command = "git",
    args = { "diff", "HEAD" },
    on_exit = function(j, exit_code)
      if exit_code == 0 then
        local diff = table.concat(j:result(), "\n")
        callback(diff)
      else
        callback("")
      end
    end,
  }):start()
end

local function notify_on_exit(success_msg, error_prefix)
  return function(_, exit_code)
    vim.schedule(function()
      if exit_code == 0 then
        vim.notify(success_msg, vim.log.levels.INFO, { title = "Git" })
      else
        vim.notify(error_prefix .. exit_code, vim.log.levels.ERROR, { title = "Git" })
      end
    end)
  end
end

local function run_git_command(args, on_exit)
  ---@diagnostic disable-next-line: missing-fields
  Job:new({
    command = "git",
    args = args,
    on_exit = on_exit
      or notify_on_exit("Git command executed successfully", "Failed to execute git command, exit code:"),
  }):start()
end

function M.commit()
  local message = vim.fn.input("Type commit message and press Enter: ")
  run_git_command({ "add", "-A" }, function()
    run_git_command(
      { "commit", "-s", "-m", message },
      notify_on_exit("Committed with message: " .. message, "Failed to commit, exit code: ")
    )
  end)
end

function M.push()
  run_git_command({ "push" }, notify_on_exit("Pushed to remote", "Failed to push to remote, exit code: "))
end

function M.commit_popup()
  -- Create a commit message popup window
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create buffer for commit message
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "filetype", "gitcommit")

  -- Add initial content to the buffer with instructions
  local initial_content = {
    "",
    "# Please enter the commit message for your changes. Lines starting",
    "# with '#' will be ignored, and an empty message aborts the commit.",
    "#",
    "# On branch: " .. vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", ""),
    "#",
    "# Press <C-g> to generate commit message with Claude Code",
    "#",
  }

  -- Add git status to the buffer
  local status_lines = vim.fn.systemlist("git status")
  for _, line in ipairs(status_lines) do
    table.insert(initial_content, "# " .. line)
  end

  api.nvim_buf_set_lines(buf, 0, -1, false, initial_content)

  -- Create window with rounded borders
  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Git Commit ",
    title_pos = "center",
  })

  -- Set local options for this buffer
  api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":q<CR>", { noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })

  -- Function to handle commit submission
  local function submit_commit()
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)

    -- Filter out comment lines
    local message_lines = {}
    for _, line in ipairs(lines) do
      if not line:match("^%s*#") then
        table.insert(message_lines, line)
      end
    end

    -- Check if there's actual content
    local message = table.concat(message_lines, "\n"):gsub("^%s*(.-)%s*$", "%1")

    if message == "" then
      vim.notify("Commit canceled: Empty commit message", vim.log.levels.WARN, { title = "Git" })
      vim.cmd("q")
      return
    end

    -- Close the window
    vim.cmd("q")

    -- First add all files
    run_git_command({ "add", "-A" }, function()
      ---@diagnostic disable-next-line: missing-fields
      Job:new({
        command = "git",
        args = { "commit", "-s", "-F", "-" },
        writer = message,
        on_exit = notify_on_exit("Committed successfully", "Failed to commit, exit code: "),
      }):start()
    end)
  end

  -- Function to generate commit message with Claude Code
  local function generate_with_claude()
    vim.notify("Generating commit message...", vim.log.levels.INFO, { title = "Git" })

    get_all_git_changes(function(changes)
      if changes == "" then
        vim.notify("No changes found", vim.log.levels.WARN, { title = "Git" })
        return
      end

      local prompt = default_preprompt .. "\n\nChanges:\n\n"

      ---@diagnostic disable-next-line: missing-fields
      local job = Job:new({
        command = "claude",
        args = { "-p", prompt },
        writer = changes,
        on_exit = function(j, exit_code)
          vim.schedule(function()
            if exit_code ~= 0 then
              vim.notify("Failed to generate commit message with Claude Code", vim.log.levels.ERROR, { title = "Git" })
              return
            end
            local result = table.concat(j:result(), "\n")

            -- Clean up the result and split into lines
            local cleaned_result = result:gsub("^%s*", ""):gsub("%s*$", "")
            local commit_lines = vim.split(cleaned_result, "\n", { plain = true })

            -- Filter out any empty lines at the start
            local filtered_lines = {}
            for _, line in ipairs(commit_lines) do
              if line:match("%S") then -- Only include lines with non-whitespace content
                table.insert(filtered_lines, line)
              end
            end

            local combined_output = vim.list_extend(filtered_lines, initial_content)
            api.nvim_buf_set_lines(buf, 0, -1, false, combined_output)
          end)
        end,
      })
      job:start()
    end)
  end

  -- Register the functions
  _G.__git_submit_commit = submit_commit
  _G.__git_generate_claude = generate_with_claude

  -- Set keybindings
  api.nvim_buf_set_keymap(
    buf,
    "n",
    "<leader>",
    [[<cmd>lua _G.__git_submit_commit()<CR>]],
    { noremap = true, silent = true, desc = "Submit commit" }
  )

  api.nvim_buf_set_keymap(
    buf,
    "i",
    "<C-g>",
    [[<cmd>lua _G.__git_generate_claude()<CR>]],
    { noremap = true, silent = true, desc = "Generate with Claude Code" }
  )

  api.nvim_buf_set_keymap(
    buf,
    "n",
    "<C-g>",
    [[<cmd>lua _G.__git_generate_claude()<CR>]],
    { noremap = true, silent = true, desc = "Generate with Claude Code" }
  )

  -- Position cursor at the top of the buffer
  api.nvim_win_set_cursor(win, { 1, 0 })
end

return M
