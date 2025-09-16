local M = {}
local api = require('nvim-slack.api')

-- List all conversations (channels, DMs, etc)
function M.list(callback)
  api.api_request('conversations.list', {
    types = 'public_channel,private_channel,mpim,im',
    exclude_archived = true,
    limit = 1000,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    -- Sort channels by name
    if data.channels then
      table.sort(data.channels, function(a, b)
        -- Handle nil names
        local a_name = a.name or a.id or ''
        local b_name = b.name or b.id or ''

        -- Prioritize channels with unread messages
        if a.has_unreads and not b.has_unreads then
          return true
        elseif b.has_unreads and not a.has_unreads then
          return false
        end

        -- Then sort by name
        return a_name < b_name
      end)
    end

    callback(data.channels or {})
  end)
end

-- Get conversation history
function M.history(channel_id, callback, options)
  options = options or {}

  api.api_request('conversations.history', {
    channel = channel_id,
    limit = options.limit or 100,
    oldest = options.oldest,
    latest = options.latest,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    -- Reverse messages so newest are at bottom
    if data.messages then
      -- Messages come in reverse chronological order
      -- We want chronological order (oldest first)
      local reversed = {}
      for i = #data.messages, 1, -1 do
        table.insert(reversed, data.messages[i])
      end
      data.messages = reversed
    end

    callback(data.messages or {}, data.has_more)
  end)
end

-- Get conversation info
function M.info(channel_id, callback)
  api.api_request('conversations.info', {
    channel = channel_id,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    callback(data.channel)
  end)
end

-- Join a conversation
function M.join(channel_id, callback)
  api.api_request('conversations.join', {
    channel = channel_id,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    callback(data.channel)
  end)
end

-- Leave a conversation
function M.leave(channel_id, callback)
  api.api_request('conversations.leave', {
    channel = channel_id,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    callback(data)
  end)
end

-- Mark channel as read
function M.mark(channel_id, timestamp, callback)
  api.api_request('conversations.mark', {
    channel = channel_id,
    ts = timestamp,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    callback(data)
  end)
end

-- Get thread replies
function M.replies(channel_id, thread_ts, callback, options)
  options = options or {}

  api.api_request('conversations.replies', {
    channel = channel_id,
    ts = thread_ts,
    limit = options.limit or 100,
    oldest = options.oldest,
    latest = options.latest,
  }, function(data, error)
    if error then
      callback(nil, error)
      return
    end

    -- Messages come in chronological order for threads
    callback(data.messages or {}, data.has_more)
  end)
end

return M
