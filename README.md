# nvim-slack

A Neovim plugin for interacting with Slack directly from your editor.

## Features

- Connect to Slack workspaces using Web API
- View channels and direct messages
- Send and receive messages
- Navigate with Vim keybindings
- Automatic updates with configurable polling interval
- Thread support for viewing and replying
- Emoji reactions

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
  'albertopfp/nvim-slack',
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
3. Under **"User Token Scopes"**, click **"Add an OAuth Scope"** and add these permissions:

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

## Configuration Options

```lua
require('nvim-slack').setup({
  -- Required
  token = 'xoxp-...', -- Your Slack user token
  
  -- Optional (shown with defaults)
  sync_interval = 2,  -- How often to poll for updates (in seconds)
  api = {
    debug = false,
    request_timeout = 5000, -- ms
  },
  ui = {
    width = 80,
    height = 30,
    position = 'center',
    channel_width = 20,
    show_timestamps = true,
    date_format = '%H:%M',
    highlight_mentions = true,
  },
})
```

## Usage

### Commands

- `:Slack` - Open Slack buffer
- `:SlackConnect` - Connect to Slack workspace
- `:SlackDisconnect` - Disconnect from Slack
- `:SlackStatus` - Show connection status

### Keybindings

All keybindings work in normal mode unless specified otherwise.

#### Navigation Between Panes
| Key | Action | From |
|-----|--------|------|
| `h` | Move to channel list | Messages pane |
| `l` | Move to messages/open channel | Channel list |
| `i` | Jump to input area | Any pane |
| `<Esc>` | Go back to messages | Input pane |

#### Channel List (left pane)
| Key | Action |
|-----|--------|
| `j` | Move down to next channel |
| `k` | Move up to previous channel |
| `<Enter>` or `l` | Open selected channel |
| `r` | Refresh channel list |
| `q` | Close Slack |
| `i` or `I` | Jump to input area |

#### Messages View (right pane)
| Key | Action |
|-----|--------|
| `j` | Select next message (move cursor down) |
| `k` | Select previous message (move cursor up) |
| `G` | Jump to bottom (latest message) |
| `h` | Go back to channel list |
| `r` | Refresh messages in current channel |
| `q` | Close Slack |
| `i` or `I` | Jump to input area |

#### Message Actions (requires selected message)
| Key | Action |
|-----|--------|
| `t` | Reply to selected message in thread |
| `e` | Add emoji reaction to selected message |
| `<Enter>` | View thread (opens thread view for any message) |

#### Thread View
| Key | Action |
|-----|--------|
| `j`/`k` | Navigate between thread messages |
| `i` | Type message (automatically replies to thread) |
| `t` | Reply to selected message in thread |
| `e` | Add emoji reaction to selected message |
| `b` | Go back to channel view |
| `r` | Refresh thread |
| `q` | Close Slack |

#### Input Area (bottom pane)
| Key | Mode | Action |
|-----|------|--------|
| `<Ctrl-Enter>` | Insert | Send message |
| `<Enter>` | Normal | Send message |
| `<Esc>` | Insert/Normal | Exit to messages pane |

#### Global Commands
| Command | Action |
|---------|--------|
| `:Slack` | Open Slack interface (auto-connects if needed) |
| `:SlackConnect` | Manually connect to Slack |
| `:SlackDisconnect` | Disconnect from Slack |
| `:SlackStatus` | Show connection status |
| `:SlackDebug` | Test connection and show debug info |


## Important Notes About Authentication

### What You Need

- A Slack app (just as an OAuth container)
- User OAuth Token (`xoxp-...`) from OAuth & Permissions page
- User Token Scopes (not Bot scopes)

## Token Security

You can provide your token in several ways:

1. In the setup function (shown above)
2. Environment variable: `export SLACK_APP_TOKEN=xoxp-...`
3. File: `~/.config/nvim/slack-token` (first line should be the token)

## Health Check

Run `:checkhealth nvim-slack` to verify your installation and configuration.

## Development Status

This plugin is in early development. Current features:
- ✅ Web API connection to Slack
- ✅ Three-pane UI (channels, messages, input)
- ✅ Configuration management
- ✅ Channel listing
- ✅ Message viewing with automatic updates
- ✅ Message sending
- ✅ Thread viewing and replying
- ✅ Emoji reactions
- ✅ Direct messages and group messages

## License

MIT
