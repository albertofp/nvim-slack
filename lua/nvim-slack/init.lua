local M = {}

-- Local state
local state = {
  connected = false,
  websocket = nil,
  config = nil,
  workspace = nil,
}

-- Setup function to initialize the plugin with user config
function M.setup(opts)
  local config = require('nvim-slack.config')
  state.config = config.setup(opts)

  -- Initialize submodules
  require('nvim-slack.websocket').setup(state.config)
  
  -- Load debug module in development
  require('nvim-slack.debug')
end

-- Connect to Slack workspace
function M.connect()
  if state.connected then
    vim.notify('Already connected to Slack', vim.log.levels.INFO)
    return
  end

  local config = require('nvim-slack.config')
  local token = config.get_token()

  if not token then
    vim.notify('No Slack token configured. Please set token in setup() or use :SlackAuth', vim.log.levels.ERROR)
    return
  end

  vim.notify('Connecting to Slack...', vim.log.levels.INFO)

  local websocket = require('nvim-slack.websocket')
  websocket.connect(token, function(success, error)
    if success then
      state.connected = true
      state.websocket = websocket
      vim.notify('Connected to Slack successfully', vim.log.levels.INFO)
    else
      vim.notify('Failed to connect to Slack: ' .. (error or 'Unknown error'), vim.log.levels.ERROR)
    end
  end)
end

-- Disconnect from Slack
function M.disconnect()
  if not state.connected then
    vim.notify('Not connected to Slack', vim.log.levels.INFO)
    return
  end

  if state.websocket then
    require('nvim-slack.websocket').disconnect()
  end

  state.connected = false
  state.websocket = nil
  vim.notify('Disconnected from Slack', vim.log.levels.INFO)
end

-- Show connection status
function M.status()
  if state.connected then
    vim.notify('Connected to Slack', vim.log.levels.INFO)
    if state.workspace then
      vim.notify('Workspace: ' .. state.workspace, vim.log.levels.INFO)
    end
  else
    vim.notify('Not connected to Slack', vim.log.levels.WARN)
  end
end

-- Open Slack buffer
function M.open()
  if not state.connected then
    vim.notify('Not connected to Slack. Connecting...', vim.log.levels.INFO)
    M.connect()
    -- Wait a moment for connection to complete
    vim.defer_fn(function()
      if state.connected then
        local ui = require('nvim-slack.ui.buffer')
        ui.open()
      else
        vim.notify('Failed to connect to Slack. Check your token configuration.', vim.log.levels.ERROR)
      end
    end, 1000)
    return
  end

  local ui = require('nvim-slack.ui.buffer')
  ui.open()
end

-- Get current state (for debugging and other modules)
function M.get_state()
  return state
end

return M

