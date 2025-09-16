local M = {}

-- Local cache for user data
local user_cache = {}

-- Get user info
function M.info(user_id, callback)
  -- Check cache first
  if user_cache[user_id] then
    callback(user_cache[user_id])
    return
  end
  
  local websocket = require('nvim-slack.api')
  
  websocket.api_request('users.info', {
    user = user_id,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    -- Cache the user data
    if data.user then
      user_cache[user_id] = data.user
    end
    
    callback(data.user)
  end)
end

-- List all users
function M.list(callback)
  local websocket = require('nvim-slack.api')
  
  websocket.api_request('users.list', {
    limit = 1000,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    -- Cache all users
    if data.members then
      for _, user in ipairs(data.members) do
        user_cache[user.id] = user
      end
    end
    
    callback(data.members or {})
  end)
end

-- Get user by ID from cache or format fallback
function M.get_display_name(user_id)
  if user_cache[user_id] then
    return user_cache[user_id].real_name or user_cache[user_id].name
  end
  return user_id
end

-- Clear user cache
function M.clear_cache()
  user_cache = {}
end

-- Batch fetch users and populate cache
function M.populate_cache(callback)
  M.list(function(users, error)
    if error then
      if callback then callback(false, error) end
      return
    end
    
    if callback then callback(true) end
  end)
end

return M