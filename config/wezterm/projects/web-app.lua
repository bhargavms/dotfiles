-- Example project-specific configuration for a web application
-- This file demonstrates how to create custom workspace configurations for specific projects

local M = {}

-- Project-specific configuration
M.config = {
  name = "web-app",
  description = "Modern web application workspace",
  
  -- Custom layout for this project
  layout = {
    description = "Web app development layout with frontend, backend, and testing",
    tabs = {
      {
        name = "frontend",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          -- Start frontend dev server
          return "npm run dev"
        end
      },
      {
        name = "backend",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          -- Start backend server
          return "npm run server"
        end
      },
      {
        name = "test",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = "vertical",
            cwd_relative = true
          },
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          -- Start test watcher in first pane
          return "npm run test:watch"
        end
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
            command = "git status",
            split = nil,
            cwd_relative = true
          }
        }
      }
    }
  },
  
  -- Custom environment variables for this project
  env = {
    NODE_ENV = "development",
    DEBUG = "app:*",
    PORT = "3000"
  },
  
  -- Custom keybindings for this workspace
  keybindings = {
    {
      key = 'r',
      mods = 'LEADER|SHIFT',
      description = 'Restart dev server',
      action = function(window, pane)
        -- Send Ctrl+C then restart command
        pane:send_text('\x03') -- Ctrl+C
        wezterm.sleep_ms(500)
        pane:send_text('npm run dev\n')
      end
    },
    {
      key = 't',
      mods = 'LEADER|SHIFT',
      description = 'Run tests',
      action = function(window, pane)
        pane:send_text('npm test\n')
      end
    }
  },
  
  -- Custom status line for this workspace
  status = {
    left = function()
      return {
        { Text = " Web App " },
        { Background = { Color = "#b7bdf8" } },
        { Foreground = { Color = "#313244" } },
        { Text = " " .. (os.getenv("NODE_ENV") or "development") .. " " },
      }
    end,
    right = function()
      return {
        { Text = " ⚛️ React " },
        { Text = " | " },
        { Text = " 🟢 Server " },
      }
    end
  },
  
  -- Project-specific startup commands
  startup_commands = {
    "npm install", -- Ensure dependencies are installed
    "git fetch",   -- Fetch latest changes
  },
  
  -- Cleanup commands when leaving workspace
  cleanup_commands = {
    -- Kill any running servers
    "pkill -f 'npm run dev'",
    "pkill -f 'npm run server'"
  }
}

-- Apply project-specific configuration
function M.apply(window, pane, project_info)
  local layouts = require('workspaces.layouts')
  
  -- Add custom layout
  layouts.add_layout(M.config.name, M.config.layout)
  
  -- Apply the layout
  layouts.apply_layout(M.config.name, project_info, window, pane)
  
  -- Set environment variables
  for key, value in pairs(M.config.env) do
    pane:send_text('export ' .. key .. '=' .. value .. '\n')
  end
  
  -- Run startup commands
  for _, command in ipairs(M.config.startup_commands) do
    pane:send_text(command .. '\n')
    wezterm.sleep_ms(1000) -- Wait between commands
  end
end

-- Cleanup when leaving project
function M.cleanup()
  for _, command in ipairs(M.config.cleanup_commands) do
    os.execute(command)
  end
end

return M 