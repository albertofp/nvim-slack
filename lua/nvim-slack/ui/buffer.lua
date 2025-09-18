---@diagnostic disable-next-line: unused-local
local types = require('nvim-slack.types')

local M = {}

---@class SlackUIState
---@field buf number?
---@field win number?
---@field channels_buf number?
---@field channels_win number?
---@field messages_buf number?
---@field messages_win number?
---@field input_buf number?
---@field input_win number?
---@field channels SlackChannel[]
---@field current_channel SlackChannel?
---@field messages SlackMessage[]
---@field message_timestamps table<number, SlackSelectedMessage>
---@field thread_messages SlackMessage[]
---@field thread_parent SlackSelectedMessage?
---@field channel_cursor number
---@field message_cursor number
---@field selected_message SlackSelectedMessage?
---@field mode string
---@field view_mode string
---@field poll_timer any
---@field last_message_count number
---@field thread_ts string?
---@field is_thread_reply boolean?

---@type SlackUIState
local state = {
  buf = nil,
  win = nil,
  channels_buf = nil,
  channels_win = nil,
  messages_buf = nil,
  messages_win = nil,
  input_buf = nil,
  input_win = nil,

  -- Data
  channels = {},
  current_channel = nil,
  messages = {},
  message_timestamps = {}, -- Store timestamps for each message line
  thread_messages = {},
  thread_parent = nil,

  -- UI state
  channel_cursor = 1,
  message_cursor = 1,
  selected_message = nil,
  mode = 'normal',       -- normal, insert, thread
  view_mode = 'channel', -- channel or thread

  -- Polling state
  poll_timer = nil,
  last_message_count = 0,
}

-- Forward declaration
local start_polling

-- Create the main Slack layout
function M.open()
  -- Close existing windows if any
  M.close()

  -- Create main container
  vim.cmd('tabnew')
  state.win = vim.api.nvim_get_current_win()
  state.buf = vim.api.nvim_get_current_buf()

  -- Set buffer name
  vim.api.nvim_buf_set_name(state.buf, '[Slack]')

  -- Calculate dimensions
  local width = vim.o.columns
  local channel_width = math.min(30, math.floor(width * 0.25))
  local input_height = 3

  -- Create channel list window (left)
  vim.cmd('topleft ' .. channel_width .. 'vnew')
  state.channels_win = vim.api.nvim_get_current_win()
  state.channels_buf = vim.api.nvim_get_current_buf()
  M.setup_channel_buffer()

  -- Create message window (right top)
  vim.cmd('wincmd l')
  state.messages_win = vim.api.nvim_get_current_win()
  state.messages_buf = vim.api.nvim_get_current_buf()
  M.setup_message_buffer()

  -- Create input window (right bottom)
  vim.cmd('rightbelow ' .. input_height .. 'new')
  state.input_win = vim.api.nvim_get_current_win()
  state.input_buf = vim.api.nvim_get_current_buf()
  M.setup_input_buffer()

  -- Go back to channels window
  vim.api.nvim_set_current_win(state.channels_win)

  -- Load initial data
  M.refresh_channels()
  
  -- Populate user cache for name resolution
  local users = require('nvim-slack.api.users')
  users.populate_cache()

  -- Set up autocommands
  M.setup_autocmds()

  -- Start polling for updates
  start_polling()
end

-- Setup channel list buffer
function M.setup_channel_buffer()
  local buf = state.channels_buf

  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'slack-channels', { buf = buf })

  if buf then
    vim.api.nvim_buf_set_name(buf, '[Slack Channels]')
  end

  -- Window options
  if state.channels_win and vim.api.nvim_win_is_valid(state.channels_win) then
    vim.api.nvim_set_option_value('number', false, { win = state.channels_win })
    vim.api.nvim_set_option_value('relativenumber', false, { win = state.channels_win })
    vim.api.nvim_set_option_value('signcolumn', 'no', { win = state.channels_win })
    vim.api.nvim_set_option_value('wrap', false, { win = state.channels_win })
  end

  -- Keymaps
  local opts = { buffer = buf, silent = true }
  vim.keymap.set('n', '<CR>', function() M.open_channel() end, opts)
  vim.keymap.set('n', 'l', function() M.open_channel() end, opts)
  vim.keymap.set('n', 'j', function() M.move_channel_cursor(1) end, opts)
  vim.keymap.set('n', 'k', function() M.move_channel_cursor(-1) end, opts)
  vim.keymap.set('n', 'r', function() M.refresh_channels() end, opts)
  vim.keymap.set('n', 'q', function() M.close() end, opts)
  vim.keymap.set('n', 'i', function() M.focus_input() end, opts)
  vim.keymap.set('n', 'I', function() M.focus_input() end, opts)
end

-- Setup message buffer
function M.setup_message_buffer()
  local buf = state.messages_buf

  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'slack-messages', { buf = buf })

  if buf then
    vim.api.nvim_buf_set_name(buf, '[Slack Messages]')
  end

  -- Window options
  if state.messages_win and vim.api.nvim_win_is_valid(state.messages_win) then
    vim.api.nvim_set_option_value('number', false, { win = state.messages_win })
    vim.api.nvim_set_option_value('relativenumber', false, { win = state.messages_win })
    vim.api.nvim_set_option_value('signcolumn', 'no', { win = state.messages_win })
    vim.api.nvim_set_option_value('wrap', true, { win = state.messages_win })
    vim.api.nvim_set_option_value('linebreak', true, { win = state.messages_win })
  end

  -- Keymaps
  local opts = { buffer = buf, silent = true }
  vim.keymap.set('n', 'h', function()
    if state.channels_win and vim.api.nvim_win_is_valid(state.channels_win) then
      vim.api.nvim_set_current_win(state.channels_win)
    end
  end, opts)
  vim.keymap.set('n', 'j', function() M.move_message_cursor(1) end, opts)
  vim.keymap.set('n', 'k', function() M.move_message_cursor(-1) end, opts)
  vim.keymap.set('n', 'G', function() M.scroll_messages_bottom() end, opts)
  vim.keymap.set('n', 'r', function() M.refresh_messages() end, opts)
  vim.keymap.set('n', 'q', function() M.close() end, opts)
  vim.keymap.set('n', 'i', function() M.focus_input() end, opts)
  vim.keymap.set('n', 'I', function() M.focus_input() end, opts)
  vim.keymap.set('n', 't', function() M.reply_to_thread() end, opts)
  vim.keymap.set('n', 'e', function() M.add_reaction() end, opts)
  vim.keymap.set('n', '<CR>', function() M.open_thread() end, opts)
  vim.keymap.set('n', 'b', function() M.go_back() end, opts)
end

-- Setup input buffer
function M.setup_input_buffer()
  local buf = state.input_buf

  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'slack-input', { buf = buf })

  if buf then
    vim.api.nvim_buf_set_name(buf, '[Slack Input]')
  end

  -- Window options
  if state.input_win and vim.api.nvim_win_is_valid(state.input_win) then
    vim.api.nvim_set_option_value('number', false, { win = state.input_win })
    vim.api.nvim_set_option_value('relativenumber', false, { win = state.input_win })
    vim.api.nvim_set_option_value('signcolumn', 'no', { win = state.input_win })
    vim.api.nvim_set_option_value('wrap', true, { win = state.input_win })
  end

  -- Initial prompt
  if buf then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Type your message...' })
  end

  -- Keymaps
  local opts = { buffer = buf, silent = true }
  vim.keymap.set('n', '<Esc>', function()
    if state.messages_win and vim.api.nvim_win_is_valid(state.messages_win) then
      vim.api.nvim_set_current_win(state.messages_win)
    end
  end, opts)
  vim.keymap.set('i', '<C-Enter>', function() M.send_message() end, opts)
  vim.keymap.set('n', '<CR>', function() M.send_message() end, opts)
end

-- Refresh channel list
function M.refresh_channels()
  local conversations = require('nvim-slack.api.conversations')

  -- Silent loading

  conversations.list(function(channels, error)
    if error then
      vim.notify('Failed to load channels: ' .. error, vim.log.levels.ERROR)
      return
    end

    state.channels = channels
    M.render_channels()

    -- Auto-select first channel
    if #channels > 0 and not state.current_channel then
      state.channel_cursor = 1
      M.open_channel()
    end
  end)
end

-- Render channel list
function M.render_channels()
  if not state.channels_buf or not vim.api.nvim_buf_is_valid(state.channels_buf) then
    return
  end

  vim.api.nvim_set_option_value('modifiable', true, { buf = state.channels_buf })

  local lines = {}
  local highlights = {}
  local users = require('nvim-slack.api.users')

  table.insert(lines, ' CHANNELS')
  table.insert(lines, ' ' .. string.rep('─', 28))

  for i, channel in ipairs(state.channels) do
    local prefix = '  '
    if channel.has_unreads then
      prefix = '● '
    end

    local name = channel.name
    if channel.is_im then
      -- Use get_display_name to get proper user display name
      local username = channel.user and users.get_display_name(channel.user) or 'direct'
      name = '@' .. username
    elseif channel.is_mpim then
      name = '@' .. (channel.name_normalized or 'group')
    else
      name = '#' .. name
    end

    -- Truncate long names
    if #name > 25 then
      name = name:sub(1, 22) .. '...'
    end

    local line = prefix .. name
    if i == state.channel_cursor then
      line = '▸ ' .. name
      table.insert(highlights, { i + 1, 'SlackChannelSelected' })
    end

    table.insert(lines, line)
  end

  vim.api.nvim_buf_set_lines(state.channels_buf, 0, -1, false, lines)

  -- Apply highlights
  local ns = vim.api.nvim_create_namespace('slack_channels')
  vim.api.nvim_buf_clear_namespace(state.channels_buf, ns, 0, -1)

  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(state.channels_buf, ns, hl[1] - 1, 0,
      { end_row = hl[1] - 1, hl_eol = true, hl_group = hl[2] })
  end

  vim.api.nvim_set_option_value('modifiable', false, { buf = state.channels_buf })
end

-- Open selected channel
function M.open_channel()
  if state.channel_cursor < 1 or state.channel_cursor > #state.channels then
    return
  end

  local channel = state.channels[state.channel_cursor]
  state.current_channel = channel

  M.refresh_messages()
end

-- Refresh messages for current channel
function M.refresh_messages()
  if not state.current_channel then
    return
  end

  local conversations = require('nvim-slack.api.conversations')

  -- Silent loading

  conversations.history(state.current_channel.id, function(messages, error)
    if error then
      vim.notify('Failed to load messages: ' .. error, vim.log.levels.ERROR)
      return
    end

    state.messages = messages
    M.render_messages()
  end)
end

-- Render messages
function M.render_messages()
  if not state.messages_buf or not vim.api.nvim_buf_is_valid(state.messages_buf) then
    return
  end

  vim.api.nvim_set_option_value('modifiable', true, { buf = state.messages_buf })

  local lines = {}
  local users = require('nvim-slack.api.users')
  state.message_timestamps = {}

  -- Header
  local channel_name = state.current_channel.name
  if state.current_channel.is_im then
    channel_name = 'Direct Message'
  elseif state.current_channel.is_mpim then
    channel_name = 'Group Message'
  else
    channel_name = '#' .. channel_name
  end

  table.insert(lines, ' ' .. channel_name)
  table.insert(lines, ' ' .. string.rep('─', vim.api.nvim_win_get_width(state.messages_win) - 2))
  table.insert(lines, '')

  -- Messages
  for i, msg in ipairs(state.messages) do
    if msg.type == 'message' and not msg.subtype then
      -- Store the line number for this message
      local message_start_line = #lines + 1
      state.message_timestamps[message_start_line] = {
        ts = msg.ts,
        user = msg.user,
        text = msg.text,
        index = i,
        reactions = msg.reactions,
        thread_ts = msg.thread_ts,
        reply_count = msg.reply_count,
      }

      -- Format timestamp
      local timestamp = os.date('%H:%M', tonumber(msg.ts))

      -- Get username
      local username = users.get_display_name(msg.user)

      -- Format message header with selection indicator
      local header = string.format('[%s] %s:', timestamp, username)
      if state.selected_message and state.selected_message.ts == msg.ts then
        header = '▸ ' .. header
      else
        header = '  ' .. header
      end

      table.insert(lines, header)

      -- Split message text by newlines
      local text_lines = vim.split(msg.text or '', '\n')
      for _, line in ipairs(text_lines) do
        table.insert(lines, '    ' .. line)
      end

      -- Show reactions if any
      if msg.reactions and #msg.reactions > 0 then
        local emoji_helper = require('nvim-slack.emoji')
        local reaction_line = '    '
        for _, reaction in ipairs(msg.reactions) do
          reaction_line = reaction_line .. emoji_helper.format_reaction(reaction.name, reaction.count) .. ' '
        end
        table.insert(lines, reaction_line)
      end

      -- Show thread indicator if any
      if msg.reply_count and msg.reply_count > 0 then
        table.insert(lines, '    💬 ' .. msg.reply_count .. ' replies')
      end

      table.insert(lines, '')
    end
  end

  vim.api.nvim_buf_set_lines(state.messages_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = state.messages_buf })

  -- Apply highlights
  local ns = vim.api.nvim_create_namespace('slack_messages')
  vim.api.nvim_buf_clear_namespace(state.messages_buf, ns, 0, -1)

  -- Highlight selected message
  if state.selected_message then
    for line_num, msg_info in pairs(state.message_timestamps) do
      if msg_info.ts == state.selected_message.ts then
        vim.api.nvim_buf_set_extmark(state.messages_buf, ns, line_num - 1, 0,
          { end_row = line_num - 1, hl_eol = true, hl_group = 'SlackMessageSelected' })
      end
    end
  end

  -- Scroll to bottom only on initial load
  if state.message_cursor == 1 then
    M.scroll_messages_bottom()
  end
end

-- Navigation functions
function M.move_channel_cursor(delta)
  state.channel_cursor = math.max(1, math.min(#state.channels, state.channel_cursor + delta))
  M.render_channels()
end

function M.move_message_cursor(delta)
  local win = state.messages_win
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  local current = vim.api.nvim_win_get_cursor(win)[1]
  local new_pos = current

  -- Find next/prev message
  if delta > 0 then
    -- Moving down - find next message
    for line = current + 1, vim.api.nvim_buf_line_count(state.messages_buf) do
      if state.message_timestamps[line] then
        new_pos = line
        break
      end
    end
  else
    -- Moving up - find previous message
    for line = current - 1, 1, -1 do
      if state.message_timestamps[line] then
        new_pos = line
        break
      end
    end
  end

  -- Update cursor position
  vim.api.nvim_win_set_cursor(win, { new_pos, 0 })

  -- Update selected message
  state.selected_message = state.message_timestamps[new_pos]
  state.message_cursor = new_pos

  -- Re-render to update selection highlight
  M.render_messages()
end

function M.scroll_messages(delta)
  local win = state.messages_win
  if win and vim.api.nvim_win_is_valid(win) then
    local current = vim.api.nvim_win_get_cursor(win)[1]
    local new_pos = math.max(1, current + delta)
    vim.api.nvim_win_set_cursor(win, { new_pos, 0 })
  end
end

function M.scroll_messages_bottom()
  local win = state.messages_win
  if win and vim.api.nvim_win_is_valid(win) then
    local line_count = vim.api.nvim_buf_line_count(state.messages_buf)
    vim.api.nvim_win_set_cursor(win, { line_count, 0 })
  end
end

function M.focus_input()
  if state.input_win and vim.api.nvim_win_is_valid(state.input_win) then
    vim.api.nvim_set_current_win(state.input_win)
  else
    return
  end
  -- Clear default prompt on first focus
  if state.input_buf and vim.api.nvim_buf_is_valid(state.input_buf) then
    local lines = vim.api.nvim_buf_get_lines(state.input_buf, 0, -1, false)
    if #lines == 1 and lines[1] == 'Type your message...' then
      vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, { '' })
    end
  end
  vim.cmd('startinsert')
end

-- Setup autocommands
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup('SlackUI', { clear = true })

  -- Auto-resize on window resize
  vim.api.nvim_create_autocmd('VimResized', {
    group = group,
    callback = function()
      -- Recalculate layout
    end,
  })

  -- Clean up on buffer delete
  for _, buf in ipairs({ state.channels_buf, state.messages_buf, state.input_buf }) do
    if buf then
      vim.api.nvim_create_autocmd('BufDelete', {
        group = group,
        buffer = buf,
        callback = function()
          M.stop_polling()
          M.close()
        end,
      })
    end
  end
end

-- Start polling for updates
start_polling = function()
  if state.poll_timer then
    return -- Already polling
  end

  local config = require('nvim-slack.config').get()
  local interval = config.sync_interval * 1000 -- Convert to milliseconds

  state.poll_timer = vim.uv.new_timer()
  if state.poll_timer then
    ---@diagnostic disable-next-line: undefined-field
    state.poll_timer:start(interval, interval, function()
      -- Schedule the update in the main thread
      vim.schedule(function()
        -- Only poll if windows are still valid
        if not state.messages_win or not vim.api.nvim_win_is_valid(state.messages_win) then
          M.stop_polling()
          return
        end

        -- Check if the Slack buffer is currently visible in any window
        local slack_visible = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          if buf == state.messages_buf or buf == state.channels_buf then
            slack_visible = true
            break
          end
        end

        if not slack_visible then
          return -- Don't poll if not visible
        end

        -- Store current cursor position and selected message
        local cursor_pos = nil
        if vim.api.nvim_win_is_valid(state.messages_win) and
            vim.api.nvim_get_current_win() == state.messages_win then
          cursor_pos = vim.api.nvim_win_get_cursor(state.messages_win)
        end

        -- Refresh appropriate view
        if state.view_mode == 'thread' and state.thread_parent then
          -- Refresh thread silently
          local thread_ts = state.thread_parent.thread_ts or state.thread_parent.ts
          local conversations = require('nvim-slack.api.conversations')

          conversations.replies(state.current_channel.id, thread_ts, function(messages, error)
            if not error and messages then
              local prev_count = #state.thread_messages
              state.thread_messages = messages

              -- Only re-render if message count changed
              if #messages ~= prev_count then
                M.render_thread()

                -- Restore cursor if it was in messages window
                if cursor_pos and vim.api.nvim_win_is_valid(state.messages_win) then
                  pcall(vim.api.nvim_win_set_cursor, state.messages_win, cursor_pos)
                end
              end
            end
          end)
        elseif state.current_channel then
          -- Refresh channel messages silently
          local conversations = require('nvim-slack.api.conversations')

          conversations.history(state.current_channel.id, function(messages, error)
            if not error and messages then
              local prev_count = #state.messages
              state.messages = messages

              -- Only re-render if message count changed
              if #messages ~= prev_count then
                M.render_messages()

                -- If new messages arrived and we were at bottom, scroll to bottom
                if #messages > prev_count and prev_count > 0 then
                  -- Check if we were near the bottom
                  if cursor_pos and vim.api.nvim_win_is_valid(state.messages_win) then
                    local line_count = vim.api.nvim_buf_line_count(state.messages_buf)
                    if cursor_pos[1] >= line_count - 5 then
                      M.scroll_messages_bottom()
                    else
                      -- Otherwise restore cursor position
                      pcall(vim.api.nvim_win_set_cursor, state.messages_win, cursor_pos)
                    end
                  end
                end
              end
            end
          end)
        end
      end)
    end)
  end
end

-- Stop polling for updates
M.stop_polling = function()
  if state.poll_timer then
    ---@diagnostic disable-next-line: undefined-field
    state.poll_timer:stop()
    ---@diagnostic disable-next-line: undefined-field
    state.poll_timer:close()
    state.poll_timer = nil
  end
end

-- Close all Slack windows
function M.close()
  -- Stop polling first
  M.stop_polling()

  for _, win in ipairs({ state.channels_win, state.messages_win, state.input_win }) do
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  state.channels_win = nil
  state.messages_win = nil
  state.input_win = nil
end

-- Get current state (for debugging)
function M.get_state()
  return state
end

-- Reply to thread
function M.reply_to_thread()
  if not state.selected_message then
    vim.notify('No message selected. Use j/k to select a message.', vim.log.levels.WARN)
    return
  end

  -- Store the thread timestamp
  state.thread_ts = state.selected_message.thread_ts or state.selected_message.ts
  state.is_thread_reply = true

  -- Focus input without prepopulating
  M.focus_input()
end

-- Add reaction to message
function M.add_reaction()
  if not state.selected_message then
    vim.notify('No message selected. Use j/k to select a message.', vim.log.levels.WARN)
    return
  end

  -- Prompt for emoji
  vim.ui.input({ prompt = 'Enter emoji name (without colons): ' }, function(emoji)
    if not emoji or emoji == '' then
      return
    end

    local reactions = require('nvim-slack.api.reactions')
    local api_state = require('nvim-slack.api')
    local user_info = api_state.get_user_info()
    local current_user_id = user_info.user_id

    -- Check if user already reacted with this emoji
    local has_reacted = false
    if state.selected_message.reactions then
      for _, reaction in ipairs(state.selected_message.reactions) do
        if reaction.name == emoji and reaction.users then
          for _, user_id in ipairs(reaction.users) do
            if user_id == current_user_id then
              has_reacted = true
              break
            end
          end
        end
      end
    end

    -- If we can't determine from the message data, try adding first
    if not has_reacted then
      -- Try to add reaction
      reactions.add(state.current_channel.id, state.selected_message.ts, emoji, function(_, error)
        if error then
          -- If error is "already_reacted", then remove it
          if error:match('already_reacted') then
            reactions.remove(state.current_channel.id, state.selected_message.ts, emoji, function(_, error2)
              if error2 then
                vim.notify('Failed to remove reaction: ' .. error2, vim.log.levels.ERROR)
                return
              end

              -- Reaction removed successfully
              M.refresh_messages()
            end)
          else
            vim.notify('Failed to add reaction: ' .. error, vim.log.levels.ERROR)
          end
          return
        end

        -- Reaction added successfully
        M.refresh_messages()
      end)
    else
      -- Remove reaction
      reactions.remove(state.current_channel.id, state.selected_message.ts, emoji, function(_, error)
        if error then
          vim.notify('Failed to remove reaction: ' .. error, vim.log.levels.ERROR)
          return
        end

        -- Reaction removed successfully
        M.refresh_messages()
      end)
    end
  end)
end

-- Open thread view
function M.open_thread()
  if not state.selected_message then
    vim.notify('No message selected. Use j/k to select a message.', vim.log.levels.WARN)
    return
  end

  -- Can open thread for any message, not just those with replies
  local thread_ts = state.selected_message.thread_ts or state.selected_message.ts

  local conversations = require('nvim-slack.api.conversations')

  conversations.replies(state.current_channel.id, thread_ts, function(messages, error)
    if error then
      vim.notify('Failed to load thread: ' .. error, vim.log.levels.ERROR)
      return
    end

    state.thread_messages = messages
    state.thread_parent = state.selected_message
    state.view_mode = 'thread'

    -- Render thread view
    M.render_thread()
  end)
end

-- Render thread view
function M.render_thread()
  if not state.messages_buf or not vim.api.nvim_buf_is_valid(state.messages_buf) then
    return
  end

  vim.api.nvim_set_option_value('modifiable', true, { buf = state.messages_buf })

  local lines = {}
  local users = require('nvim-slack.api.users')
  state.message_timestamps = {}

  -- Header
  local channel_name = state.current_channel.name or 'channel'
  if state.current_channel.is_im then
    channel_name = 'Direct Message'
  else
    channel_name = '#' .. channel_name
  end

  table.insert(lines, ' Thread in ' .. channel_name .. ' [Press b to go back]')
  table.insert(lines, ' ' .. string.rep('─', vim.api.nvim_win_get_width(state.messages_win) - 2))
  table.insert(lines, '')

  -- Thread messages
  for i, msg in ipairs(state.thread_messages) do
    if msg.type == 'message' then
      -- Store the line number for this message
      local message_start_line = #lines + 1
      state.message_timestamps[message_start_line] = {
        ts = msg.ts,
        user = msg.user,
        text = msg.text,
        index = i,
        reactions = msg.reactions,
      }

      -- Format timestamp
      local timestamp = os.date('%H:%M', tonumber(msg.ts))

      -- Get username
      local username = users.get_display_name(msg.user)

      -- Format message header
      local header = string.format('[%s] %s:', timestamp, username)
      if i == 1 then
        header = '● ' .. header .. ' (original)'
      elseif state.selected_message and state.selected_message.ts == msg.ts then
        header = '▸ ' .. header
      else
        header = '  ' .. header
      end

      table.insert(lines, header)

      -- Split message text by newlines
      local text_lines = vim.split(msg.text or '', '\n')
      for _, line in ipairs(text_lines) do
        table.insert(lines, '    ' .. line)
      end

      -- Show reactions if any
      if msg.reactions and #msg.reactions > 0 then
        local emoji_helper = require('nvim-slack.emoji')
        local reaction_line = '    '
        for _, reaction in ipairs(msg.reactions) do
          reaction_line = reaction_line .. emoji_helper.format_reaction(reaction.name, reaction.count) .. ' '
        end
        table.insert(lines, reaction_line)
      end

      table.insert(lines, '')
    end
  end

  vim.api.nvim_buf_set_lines(state.messages_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = state.messages_buf })

  -- Apply highlights
  local ns = vim.api.nvim_create_namespace('slack_messages')
  vim.api.nvim_buf_clear_namespace(state.messages_buf, ns, 0, -1)

  -- Highlight selected message
  if state.selected_message then
    for line_num, msg_info in pairs(state.message_timestamps) do
      if msg_info.ts == state.selected_message.ts then
        vim.api.nvim_buf_set_extmark(state.messages_buf, ns, line_num - 1, 0,
          { end_row = line_num - 1, hl_eol = true, hl_group = 'SlackMessageSelected' })
      end
    end
  end

  -- Scroll to bottom
  M.scroll_messages_bottom()
end

-- Go back from thread view
function M.go_back()
  if state.view_mode == 'thread' then
    state.view_mode = 'channel'
    state.thread_messages = {}
    state.thread_parent = nil
    M.render_messages()
  end
end

-- Send message (handles threads)
function M.send_message()
  if not state.current_channel then
    vim.notify('No channel selected', vim.log.levels.WARN)
    return
  end

  -- Get input text
  if not state.input_buf or not vim.api.nvim_buf_is_valid(state.input_buf) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(state.input_buf, 0, -1, false)
  local text = table.concat(lines, '\n')

  -- Remove default prompt
  if text == 'Type your message...' then
    text = ''
  end

  text = vim.trim(text)

  if text == '' then
    return
  end

  local chat = require('nvim-slack.api.chat')

  -- Silent sending

  local options = {}
  if state.thread_ts then
    options.thread_ts = state.thread_ts
  elseif state.view_mode == 'thread' and state.thread_parent then
    -- If in thread view, default to replying to that thread
    options.thread_ts = state.thread_parent.thread_ts or state.thread_parent.ts
  end

  chat.post_message(state.current_channel.id, text, function(_, error)
    if error then
      vim.notify('Failed to send message: ' .. error, vim.log.levels.ERROR)
      return
    end

    -- Message sent successfully

    -- Clear input and thread state
    if state.input_buf and vim.api.nvim_buf_is_valid(state.input_buf) then
      vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, { '' })
    end
    state.thread_ts = nil
    state.is_thread_reply = false

    -- Refresh appropriate view
    if state.view_mode == 'thread' then
      M.open_thread() -- Refresh thread view
    else
      M.refresh_messages()
    end
  end, options)
end

-- Define highlight groups
vim.api.nvim_set_hl(0, 'SlackChannelSelected', { bold = true, fg = '#00ff00' })
vim.api.nvim_set_hl(0, 'SlackMessageSelected', { bg = '#333333' })

return M
