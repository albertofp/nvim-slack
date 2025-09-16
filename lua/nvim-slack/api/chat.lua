local M = {}
local api = require('nvim-slack.api')

-- Post a message to a channel
function M.post_message(channel_id, text, callback, options)
  options = options or {}

  local params = {
    channel = channel_id,
    text = text,
    as_user = true, -- Post as the authenticated user
  }

  -- Add optional parameters
  if options.thread_ts then
    params.thread_ts = options.thread_ts
  end

  if options.reply_broadcast then
    params.reply_broadcast = true
  end

  api.api_request('chat.postMessage', params, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    callback(data)
  end)
end

-- Update a message
function M.update(channel_id, timestamp, text, callback)
  api.api_request('chat.update', {
    channel = channel_id,
    ts = timestamp,
    text = text,
    as_user = true,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    callback(data)
  end)
end

-- Delete a message
function M.delete(channel_id, timestamp, callback)
  api.api_request('chat.delete', {
    channel = channel_id,
    ts = timestamp,
    as_user = true,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    callback(data)
  end)
end

-- Post an ephemeral message (only visible to one user)
function M.post_ephemeral(channel_id, user_id, text, callback)
  api.api_request('chat.postEphemeral', {
    channel = channel_id,
    user = user_id,
    text = text,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    callback(data)
  end)
end

return M
