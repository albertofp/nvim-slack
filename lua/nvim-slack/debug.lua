local M = {}

-- Debug command to test the connection
function M.test_connection()
  local config = require('nvim-slack.config')
  local token = config.get_token()

  if not token then
    vim.notify('No token found. Please configure token.', vim.log.levels.ERROR)
    return
  end

  vim.notify('Testing connection with token: ' .. token:sub(1, 10) .. '...', vim.log.levels.INFO)

  -- Test curl command directly with auth.test endpoint
  local cmd = {
    'curl', '-s', '-w', '\n%{http_code}',
    '-X', 'POST',
    '-H', 'Authorization: Bearer ' .. token,
    '-H', 'Content-Type: application/x-www-form-urlencoded',
    'https://slack.com/api/auth.test'
  }

  vim.notify('Running curl command...', vim.log.levels.INFO)
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  vim.notify('Exit code: ' .. exit_code, vim.log.levels.INFO)
  vim.notify('Response: ' .. vim.inspect(result), vim.log.levels.INFO)

  -- Try to parse
  local lines = vim.split(result, '\n')
  local status_code = tonumber(lines[#lines])
  if status_code then
    vim.notify('HTTP Status: ' .. status_code, vim.log.levels.INFO)
  end

  -- Try to parse JSON
  local body = table.concat(vim.list_slice(lines, 1, #lines - 1), '\n')
  local ok, data = pcall(vim.json.decode, body)
  if ok then
    vim.notify('Parsed response: ' .. vim.inspect(data), vim.log.levels.INFO)
  else
    vim.notify('Failed to parse JSON: ' .. data, vim.log.levels.ERROR)
  end
end

-- Add debug command
vim.api.nvim_create_user_command('SlackDebug', function()
  M.test_connection()
end, { desc = 'Debug Slack connection' })

return M

