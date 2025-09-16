local M = {}
local api = require('nvim-slack.api')

-- Local cache for user data
local user_cache = {}

-- Get user info
function M.info(user_id, callback)
  -- Check cache first
  if user_cache[user_id] then
    callback(user_cache[user_id])
    return
  end

  api.api_request('users.info', {
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
  api.api_request('users.list', {
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

-- Clean username by removing invisible Unicode characters
local function clean_username(name)
  if not name then return name end

  -- Remove zero-width spaces and other problematic characters
  -- Use byte patterns for UTF-8 sequences
  name = name:gsub('\226\128\139', '') -- Zero-width space (U+200B)
  name = name:gsub('\226\128\140', '') -- Zero-width non-joiner (U+200C)
  name = name:gsub('\226\128\141', '') -- Zero-width joiner (U+200D)
  name = name:gsub('\239\187\191', '') -- Zero-width no-break space/BOM (U+FEFF)

  -- Remove any other control characters or weird spacing
  name = name:gsub('[\1-\31]', '') -- ASCII control characters
  name = name:gsub('\194\173', '') -- Soft hyphen (U+00AD)

  return name
end

-- Get user by ID from cache or format fallback
function M.get_display_name(user_id)
  if user_cache[user_id] then
    local user = user_cache[user_id]
    -- Prioritize display_name, then real_name, then name (username)
    local display = user.display_name and user.display_name ~= "" and user.display_name
        or user.real_name and user.real_name ~= "" and user.real_name
        or user.name and user.name ~= "" and user.name
        or user_id
    return clean_username(display)
  end

  -- If not in cache, try to fetch it asynchronously for future use
  -- but return the user_id for now
  M.info(user_id, function() end) -- Fetch in background

  return user_id
end

-- Get a shorter name for compact display (username preferred over real name)
function M.get_username(user_id)
  if user_cache[user_id] then
    local user = user_cache[user_id]
    -- For compact display, prefer username over real name
    local username = user.name or user.display_name or user.real_name or user_id
    return clean_username(username)
  end

  -- If not in cache, try to fetch it asynchronously for future use
  M.info(user_id, function() end) -- Fetch in background

  return user_id
end

-- Clear user cache
function M.clear_cache()
  user_cache = {}
end

-- Batch fetch users and populate cache
function M.populate_cache(callback)
  M.list(function(_, error)
    if error then
      if callback then callback(false, error) end
      return
    end

    if callback then callback(true) end
  end)
end

return M
