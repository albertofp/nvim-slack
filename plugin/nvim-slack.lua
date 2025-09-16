-- nvim-slack plugin auto-loader
-- This file is automatically loaded by Neovim

if vim.g.loaded_nvim_slack then
  return
end
vim.g.loaded_nvim_slack = true

-- Define the main :Slack command
vim.api.nvim_create_user_command('Slack', function()
  require('nvim-slack').open()
end, { desc = 'Open Slack buffer' })

-- Define authentication command
vim.api.nvim_create_user_command('SlackConnect', function()
  require('nvim-slack').connect()
end, { desc = 'Connect to Slack workspace' })

-- Define disconnect command
vim.api.nvim_create_user_command('SlackDisconnect', function()
  require('nvim-slack').disconnect()
end, { desc = 'Disconnect from Slack workspace' })

-- Define status command
vim.api.nvim_create_user_command('SlackStatus', function()
  require('nvim-slack').status()
end, { desc = 'Show Slack connection status' })
