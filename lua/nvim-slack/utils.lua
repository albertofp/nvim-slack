local M = {}
local uv = vim.loop

-- HTTP client with better error handling
function M.curl(opts)
  -- Try to use plenary if available
  local has_plenary, plenary = pcall(require, 'plenary.curl')
  if has_plenary then
    local res = plenary.post(opts.url, {
      headers = opts.headers,
      body = opts.data,
      timeout = opts.timeout or 5000,
    })

    if opts.callback then
      opts.callback({
        status = res.status,
        headers = res.headers,
        body = res.body,
        error = res.status == 0 and 'Connection failed' or nil
      })
    end
    return
  end

  -- Fallback to curl command
  local cmd = { 'curl', '-s', '-w', '\n%{http_code}' }

  -- Method
  if opts.method and opts.method ~= 'GET' then
    table.insert(cmd, '-X')
    table.insert(cmd, opts.method)
  end

  -- Headers
  if opts.headers then
    for key, value in pairs(opts.headers) do
      table.insert(cmd, '-H')
      table.insert(cmd, string.format('%s: %s', key, value))
    end
  end

  -- Data
  if opts.data then
    table.insert(cmd, '-d')
    table.insert(cmd, opts.data)
  end

  -- URL must be last
  table.insert(cmd, opts.url)

  -- Execute curl synchronously for now
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    if opts.callback then
      opts.callback({
        status = 0,
        error = 'curl failed with exit code: ' .. exit_code
      })
    end
    return
  end

  -- Parse response - last line is status code
  local lines = vim.split(result, '\n')
  local status_code = tonumber(lines[#lines]) or 0
  table.remove(lines) -- Remove status code line
  local body = table.concat(lines, '\n')

  if opts.callback then
    opts.callback({
      status = status_code,
      body = body,
      headers = {},
      error = status_code == 0 and 'Failed to connect' or nil
    })
  end
end

-- Format timestamp
function M.format_timestamp(timestamp, format)
  format = format or '%H:%M'
  return os.date(format, tonumber(timestamp))
end

-- Escape special characters for display
function M.escape_text(text)
  return text:gsub('[<>&]', {
    ['<'] = '&lt;',
    ['>'] = '&gt;',
    ['&'] = '&amp;',
  })
end

-- Parse Slack's mrkdwn format
function M.parse_mrkdwn(text)
  -- Basic conversion of Slack markdown to plain text
  local result = text

  -- Bold: *text* -> text
  result = result:gsub('%*([^%*]+)%*', '%1')

  -- Italic: _text_ -> text
  result = result:gsub('_([^_]+)_', '%1')

  -- Strike: ~text~ -> text
  result = result:gsub('~([^~]+)~', '%1')

  -- Code: `text` -> text
  result = result:gsub('`([^`]+)`', '%1')

  -- Links: <url|text> -> text
  result = result:gsub('<[^|>]+|([^>]+)>', '%1')

  -- Links without text: <url> -> url
  result = result:gsub('<([^>]+)>', '%1')

  -- User mentions: <@U12345> -> @user
  result = result:gsub('<@(U%w+)>', function(user_id)
    -- In real implementation, resolve user name
    return '@user'
  end)

  -- Channel mentions: <#C12345|channel> -> #channel
  result = result:gsub('<#C%w+|([^>]+)>', '#%1')

  return result
end

-- Truncate text with ellipsis
function M.truncate(text, max_length)
  if #text <= max_length then
    return text
  end
  return text:sub(1, max_length - 3) .. '...'
end

-- Create a debounced function
function M.debounce(fn, delay)
  local timer
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
    end
    timer = uv.new_timer()
    timer:start(delay, 0, function()
      timer:stop()
      fn(unpack(args))
    end)
  end
end

-- Deep copy a table
function M.deep_copy(orig)
  local copy
  if type(orig) == 'table' then
    copy = {}
    for k, v in next, orig, nil do
      copy[M.deep_copy(k)] = M.deep_copy(v)
    end
    setmetatable(copy, M.deep_copy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

-- Check if value is in table
function M.contains(table, value)
  for _, v in ipairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

return M
