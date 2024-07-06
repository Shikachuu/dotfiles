local Job = require('plenary.job')

function Git_commit()
  local message = vim.fn.input('Type commit message and press Enter: ')
  Job:new({
    command = 'git',
    args = { 'add', '-A' },
    on_exit = function()
      Job:new({
        command = 'git',
        args = { 'commit', '-s', '-m', message },
        on_exit = function(_, exit_code)
          vim.schedule(function()
            if exit_code == 0 then
              vim.notify('Committed with message: ' .. message, vim.log.levels.INFO, { title = 'Git' })
            else
              vim.notify('Failed to commit, exit code:' .. exit_code, vim.log.levels.ERROR, { title = 'Git' })
            end
          end)
        end,
      }):start()
    end,
  }):start()
end

function Git_push()
  Job:new({
    command = 'git',
    args = { 'push' },
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          vim.notify('Pushed to remote', vim.log.levels.INFO, { title = 'Git' })
        else
          vim.notify('Failed to push to remote, exit code:' .. exit_code, vim.log.levels.ERROR, { title = 'Git' })
        end
      end)
    end,
  }):start()
end
-- vim: ts=2 sts=2 sw=2 et
