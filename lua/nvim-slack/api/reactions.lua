local M = {}

-- Add a reaction to a message
function M.add(channel_id, timestamp, emoji, callback)
  local api = require('nvim-slack.api')
  
  api.api_request('reactions.add', {
    channel = channel_id,
    timestamp = timestamp,
    name = emoji,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    callback(data)
  end)
end

-- Remove a reaction from a message
function M.remove(channel_id, timestamp, emoji, callback)
  local api = require('nvim-slack.api')
  
  api.api_request('reactions.remove', {
    channel = channel_id,
    timestamp = timestamp,
    name = emoji,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    callback(data)
  end)
end

-- Get reactions for a message
function M.get(channel_id, timestamp, callback)
  local api = require('nvim-slack.api')
  
  api.api_request('reactions.get', {
    channel = channel_id,
    timestamp = timestamp,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    callback(data.message)
  end)
end

-- List reactions made by a user
function M.list(user_id, callback)
  local api = require('nvim-slack.api')
  
  api.api_request('reactions.list', {
    user = user_id,
    limit = 100,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end
    
    callback(data.items or {})
  end)
end

return M