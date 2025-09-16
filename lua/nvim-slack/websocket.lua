local M = {}

-- Local state
local state = {
  connected = false,
  config = nil,
}

-- For user tokens, we'll use the Web API instead of WebSocket
-- since RTM is deprecated and Socket Mode is for apps

-- Setup WebSocket module
function M.setup(config)
  state.config = config
end

-- Connect to Slack (using Web API for user tokens)
function M.connect(token, callback)
  local utils = require('nvim-slack.utils')
  
  -- Verify token by making a test API call
  utils.curl({
    url = 'https://slack.com/api/auth.test',
    method = 'POST',
    headers = {
      ['Authorization'] = 'Bearer ' .. token,
      ['Content-Type'] = 'application/x-www-form-urlencoded',
    },
    data = '',
    callback = function(response)
      if response.error then
        callback(false, 'Network error: ' .. response.error)
        return
      end
      
      if response.status ~= 200 then
        callback(false, 'HTTP error: ' .. response.status .. ' - ' .. (response.body or ''))
        return
      end
      
      local ok, data = pcall(vim.json.decode, response.body)
      if not ok then
        callback(false, 'Failed to parse response: ' .. data)
        return
      end
      
      if not data.ok then
        callback(false, 'Slack API error: ' .. (data.error or 'Unknown error'))
        return
      end
      
      -- Store user info
      state.user_id = data.user_id
      state.team_id = data.team_id
      state.user = data.user
      state.team = data.team
      
      vim.notify('Authenticated as ' .. data.user .. ' in ' .. data.team, vim.log.levels.INFO)
      
      -- Mark as connected (we'll use polling for updates)
      state.connected = true
      callback(true)
    end,
  })
end

-- Disconnect from Slack
function M.disconnect()
  state.connected = false
  state.user_id = nil
  state.team_id = nil
end

-- Make API request
function M.api_request(method, params, callback)
  if not state.connected then
    callback(nil, 'Not connected')
    return
  end
  
  local utils = require('nvim-slack.utils')
  local config = require('nvim-slack.config').get()
  
  -- Build form data
  local form_data = {}
  for k, v in pairs(params or {}) do
    table.insert(form_data, k .. '=' .. vim.fn.escape(tostring(v), ' '))
  end
  local data = table.concat(form_data, '&')
  
  utils.curl({
    url = 'https://slack.com/api/' .. method,
    method = 'POST',
    headers = {
      ['Authorization'] = 'Bearer ' .. config.token,
      ['Content-Type'] = 'application/x-www-form-urlencoded',
    },
    data = data,
    callback = function(response)
      if response.error then
        callback(nil, 'Network error: ' .. response.error)
        return
      end
      
      if response.status ~= 200 then
        callback(nil, 'HTTP error: ' .. response.status)
        return
      end
      
      local ok, result = pcall(vim.json.decode, response.body)
      if not ok then
        callback(nil, 'Failed to parse response')
        return
      end
      
      if not result.ok then
        callback(nil, result.error or 'Unknown error')
        return
      end
      
      callback(result)
    end,
  })
end

-- Get connection status
function M.is_connected()
  return state.connected
end

-- Get user info
function M.get_user_info()
  return {
    user_id = state.user_id,
    team_id = state.team_id,
    user = state.user,
    team = state.team,
  }
end

return M