# nvim-slack

A Neovim plugin for interacting with Slack directly from your editor.

## Features

- Connect to Slack workspaces using Socket Mode
- View channels and direct messages
- Send and receive messages
- Navigate with Vim keybindings
- Real-time updates via WebSocket

## Requirements

- Neovim 0.8+
- `curl` command available in PATH
- A personal Slack app with user token

### Optional Dependencies

- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Recommended for better HTTP handling

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'albertopluecker/nvim-slack',
  dependencies = {
    'nvim-lua/plenary.nvim', -- Optional but recommended
  },
  config = function()
    require('nvim-slack').setup({
      token = 'xapp-1-YOUR-APP-TOKEN'
    })
  end
}
```

## Setup - Complete Authentication Guide

### Step 1: Create a Slack App (Required)

The app is just a container for OAuth configuration - you need it to get your user token.

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **"Create New App"**
3. Choose **"From scratch"**
4. Enter:
   - **App Name**: Something personal like "YourName Neovim" (e.g., "John's Neovim")
   - **Pick a workspace**: Select your workplace workspace
5. Click **"Create App"**

### Step 2: Configure OAuth Scopes

This tells Slack what your app can do as you.

1. In your app settings, click **"OAuth & Permissions"** in the left sidebar
2. Scroll down to **"Scopes"** section
3. **⚠️ IMPORTANT: Look for "User Token Scopes" NOT "Bot Token Scopes"!**
   - User Token Scopes = You acting as yourself
   - Bot Token Scopes = A bot acting separately (we don't want this)
4. Under **"User Token Scopes"**, click **"Add an OAuth Scope"** and add these permissions:

**Required Scopes:**
- `chat:write` - Send messages as you
- `channels:read` - List public channels
- `channels:history` - Read public channel messages
- `users:read` - Get user info (for @mentions)

**Recommended Additional Scopes:**
- `groups:read` - List private channels you're in
- `groups:history` - Read private channel messages
- `im:read` - List your DMs
- `im:history` - Read DM history
- `im:write` - Send DMs
- `mpim:read` - List group DMs
- `mpim:history` - Read group DM history
- `mpim:write` - Send group DMs
- `channels:write` - Join/leave channels
- `reactions:read` - See emoji reactions
- `reactions:write` - Add emoji reactions

### Step 3: Install App to Workspace

1. Still in **"OAuth & Permissions"**, scroll to the top
2. Click **"Install to Workspace"** button
3. Slack will show you what permissions the app is requesting
4. Click **"Allow"**
5. You'll be redirected back to your app page

**Note**: If you see "Request to Install" instead, your workspace requires admin approval.

### Step 4: Get Your User OAuth Token

1. After installation, you're back on the **"OAuth & Permissions"** page
2. You'll now see a section called **"OAuth Tokens for Your Workspace"**
3. Copy the **"User OAuth Token"** - it starts with `xoxp-`
4. This is YOUR token that represents you in Slack

### Step 5: Configure the Plugin

Use the User OAuth Token in your Neovim config:

```lua
require('nvim-slack').setup({
  -- Your User OAuth Token from Step 4
  token = 'xoxp-...'
})
```

## Usage

### Commands

- `:Slack` - Open Slack buffer
- `:SlackConnect` - Connect to Slack workspace
- `:SlackDisconnect` - Disconnect from Slack
- `:SlackStatus` - Show connection status

### Keybindings (in Slack buffer)

- `q` - Close Slack buffer
- `<C-r>` - Refresh current view
- More keybindings coming soon!


## Important Notes About Authentication

### What You Need vs What You Don't

**You DO need:**
- A Slack app (just as an OAuth container)
- User OAuth Token (`xoxp-...`) from OAuth & Permissions page
- User Token Scopes (not Bot scopes)

**You DON'T need:**
- App-Level Token (`xapp-...`) - This is for Socket Mode
- Bot User OAuth Token (`xoxb-...`) - This is for bots
- Socket Mode enabled
- Event Subscriptions
- Webhooks
- Verification tokens

### How It Works

1. The Slack app is just a container for OAuth configuration
2. Installing the app to your workspace generates a User OAuth Token
3. This token represents YOU and performs all actions as YOU
4. Messages appear as sent by you, not by a bot
5. You can only see/access channels that you personally have access to

## Token Security

You can provide your token in several ways:

1. In the setup function (shown above)
2. Environment variable: `export SLACK_APP_TOKEN=xoxp-...`
3. File: `~/.config/nvim/slack-token` (first line should be the token)

## Health Check

Run `:checkhealth nvim-slack` to verify your installation and configuration.

## Development Status

This plugin is in early development. Current features:
- ✅ WebSocket connection to Slack
- ✅ Basic UI buffer
- ✅ Configuration management
- 🚧 Channel listing
- 🚧 Message viewing
- 🚧 Message sending

## License

MIT
