local M = {}

-- Default configuration
local defaults = {
  -- Authentication
  token = nil, -- Slack user token (xoxp-...)
  
  -- API settings
  api = {
    debug = false,
    request_timeout = 5000, -- ms
  },
  
  -- UI Settings
  ui = {
    width = 80,
    height = 30,
    position = 'center',
    channel_width = 20,
    show_timestamps = true,
    date_format = '%H:%M',
    highlight_mentions = true,
  },
  
  -- Behavior
  auto_mark_read = true,
  show_typing_indicator = true,
  max_message_length = 4000,
  
  -- Performance
  cache_messages = 100,
  sync_interval = 30, -- seconds
  request_timeout = 5000, -- ms
  
  -- Keymaps
  keymaps = {
    send_message = '<CR>',
    cancel_message = '<Esc>',
    navigate_up = 'k',
    navigate_down = 'j',
    navigate_channels = 'h',
    navigate_messages = 'l',
    refresh = '<C-r>',
    quit = 'q',
  }
}

-- Current configuration
local config = {}

-- Merge user config with defaults
local function merge_config(user_opts)
  config = vim.tbl_deep_extend('force', defaults, user_opts or {})
  
  -- Validate token
  if config.token and not config.token:match('^xoxp%-') then
    vim.notify('Warning: Token should be a user token starting with "xoxp-"', vim.log.levels.WARN)
  end
  
  return config
end

-- Setup configuration
function M.setup(opts)
  return merge_config(opts)
end

-- Get current configuration
function M.get()
  return config
end

-- Get specific config value
function M.get_value(path)
  local value = config
  for key in path:gmatch('[^.]+') do
    value = value[key]
    if value == nil then
      return nil
    end
  end
  return value
end

-- Get token (with environment variable fallback)
function M.get_token()
  if config.token then
    return config.token
  end
  
  -- Try environment variable
  local env_token = os.getenv('SLACK_APP_TOKEN')
  if env_token then
    return env_token
  end
  
  -- Try to read from secure file
  local token_file = vim.fn.expand('~/.config/nvim/slack-token')
  if vim.fn.filereadable(token_file) == 1 then
    local lines = vim.fn.readfile(token_file)
    if #lines > 0 then
      return vim.trim(lines[1])
    end
  end
  
  return nil
end

-- Update configuration value
function M.update(key, value)
  config[key] = value
end

-- Validate configuration
function M.validate()
  local ok = true
  local errors = {}
  
  if not M.get_token() then
    ok = false
    table.insert(errors, 'No Slack token configured')
  end
  
  if config.websocket.ping_interval < 10 then
    ok = false
    table.insert(errors, 'WebSocket ping interval should be at least 10 seconds')
  end
  
  return ok, errors
end

return M