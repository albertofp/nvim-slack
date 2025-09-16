local M = {}

local state = {
  buf = nil,
  win = nil,
}

-- Create or get the Slack buffer
local function get_or_create_buffer()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end
  
  -- Create new buffer
  state.buf = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer options
  local buf_opts = {
    buftype = 'nofile',
    bufhidden = 'hide',
    swapfile = false,
    modifiable = false,
    filetype = 'slack',
  }
  
  for opt, val in pairs(buf_opts) do
    vim.api.nvim_buf_set_option(state.buf, opt, val)
  end
  
  -- Set buffer name
  vim.api.nvim_buf_set_name(state.buf, '[Slack]')
  
  return state.buf
end

-- Open Slack buffer in a window
function M.open()
  local buf = get_or_create_buffer()
  
  -- Check if window already exists
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    return
  end
  
  -- Create new window
  vim.cmd('new')
  state.win = vim.api.nvim_get_current_win()
  
  -- Set window to use our buffer
  vim.api.nvim_win_set_buf(state.win, buf)
  
  -- Set window options
  local win_opts = {
    number = false,
    relativenumber = false,
    signcolumn = 'no',
    wrap = true,
    linebreak = true,
  }
  
  for opt, val in pairs(win_opts) do
    vim.api.nvim_win_set_option(state.win, opt, val)
  end
  
  -- Initial content
  M.render()
  
  -- Set up keymaps
  M.setup_keymaps()
end

-- Render the buffer content
function M.render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  
  local lines = {
    '╭─────────────────────────────────────────────╮',
    '│            Slack for Neovim                 │',
    '╰─────────────────────────────────────────────╯',
    '',
  }
  
  local plugin_state = require('nvim-slack').get_state()
  
  if plugin_state.connected then
    table.insert(lines, '✓ Connected to Slack')
    table.insert(lines, '')
    table.insert(lines, 'Commands:')
    table.insert(lines, '  q     - Close this window')
    table.insert(lines, '  <C-r> - Refresh')
  else
    table.insert(lines, '✗ Not connected to Slack')
    table.insert(lines, '')
    table.insert(lines, 'Run :SlackConnect to connect')
  end
  
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
end

-- Setup buffer keymaps
function M.setup_keymaps()
  local config = require('nvim-slack.config').get()
  local keymaps = config.keymaps
  
  local opts = { buffer = state.buf, silent = true }
  
  -- Quit
  vim.keymap.set('n', keymaps.quit, function()
    M.close()
  end, opts)
  
  -- Refresh
  vim.keymap.set('n', keymaps.refresh, function()
    M.render()
    vim.notify('Refreshed', vim.log.levels.INFO)
  end, opts)
end

-- Close the Slack window
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end
end

-- Get current buffer and window
function M.get_state()
  return state
end

return M