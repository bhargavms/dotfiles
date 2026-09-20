-- Default workspace template
-- This serves as a fallback configuration for unrecognized project types

local M = {}

-- Default project configuration
M.config = {
  name = "default",
  description = "Default workspace template for general development",

  -- Basic three-tab layout
  layout = {
    description = "General purpose development layout",
    tabs = {
      {
        name = "main",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        }
      },
      {
        name = "tools",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = "horizontal",
            cwd_relative = true
          },
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        }
      },
      {
        name = "git",
        cwd_relative = true,
        panes = {
          {
            command = "git status",
            split = nil,
            cwd_relative = true
          }
        }
      }
    }
  },

  -- Basic environment setup
  env = {
    EDITOR = "nvim",
    PAGER = "less"
  },

  -- Standard development keybindings
  keybindings = {
    {
      key = 'g',
      mods = 'LEADER|SHIFT',
      description = 'Git status',
      action = function(window, pane)
        pane:send_text('git status\n')
      end
    },
    {
      key = 'l',
      mods = 'LEADER|SHIFT',
      description = 'List files',
      action = function(window, pane)
        pane:send_text('ls -la\n')
      end
    }
  },

  -- Basic startup commands
  startup_commands = {
    "pwd",
    "ls -la"
  }
}

-- Apply default configuration
function M.apply(window, pane, project_info)
  local layouts = require('workspaces.layouts')

  -- Apply the general development layout
  layouts.apply_layout("general-development", project_info, window, pane)

  -- Set environment variables
  for key, value in pairs(M.config.env) do
    pane:send_text('export ' .. key .. '=' .. value .. '\n')
  end

  -- Show welcome message
  local workspace_name = window:active_workspace()
  window:toast_notification('Workspace Created', 'Default workspace: ' .. workspace_name, nil, 3000)
end

return M
