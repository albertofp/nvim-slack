local M = {}
local health = vim.health or require('health')
local config = require('nvim-slack.config')

function M.check()
  health.report_start('nvim-slack')

  -- Check Neovim version
  local nvim_version = vim.version()
  if nvim_version.major == 0 and nvim_version.minor < 8 then
    health.report_error(
      string.format('Neovim version 0.8+ required, found %d.%d.%d',
        nvim_version.major, nvim_version.minor, nvim_version.patch)
    )
  else
    health.report_ok(
      string.format('Neovim version %d.%d.%d',
        nvim_version.major, nvim_version.minor, nvim_version.patch)
    )
  end

  -- Check configuration
  local token = config.get_token()

  if token then
    if token:match('^xoxp%-') then
      health.report_ok('Slack app token found')
    else
      health.report_warn('Slack token found but does not start with "xoxp-"')
    end
  else
    health.report_error('No Slack token configured')
    health.report_info('Set token in setup() or environment variable SLACK_APP_TOKEN')
  end

  -- Check curl availability
  local curl_exists = vim.fn.executable('curl') == 1
  if curl_exists then
    health.report_ok('curl is available')
  else
    health.report_error('curl not found in PATH (required for HTTP requests)')
  end

  -- Check connection
  local plugin_state = require('nvim-slack').get_state()
  if plugin_state.connected then
    health.report_ok('Connected to Slack')
  else
    health.report_info('Not connected to Slack (run :SlackConnect)')
  end

  -- Check optional dependencies
  local has_plenary = pcall(require, 'plenary')
  if has_plenary then
    health.report_ok('plenary.nvim found (optional)')
  else
    health.report_info('plenary.nvim not found (optional, for enhanced HTTP)')
  end
end

return M
