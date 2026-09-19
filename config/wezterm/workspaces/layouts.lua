local wezterm = require 'wezterm'

local M = {}

-- Configuration will be set by manager
local config = {}

-- Layout definitions
local layout_templates = {
  ["web-development"] = {
    description = "Web development layout with dev server, testing, and git",
    tabs = {
      {
        name = "dev",
        cwd_relative = true,
        panes = {
          {
            command = nil, -- Just shell
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          -- Auto-start dev server if package.json has dev script
          if project_info and project_info.type == "nodejs" then
            local package_file = project_info.path .. "/package.json"
            local file = io.open(package_file, "r")
            if file then
              local content = file:read("*all")
              file:close()
              local parsed = wezterm.json_parse(content)
              if parsed and parsed.scripts and parsed.scripts.dev then
                -- Send command to start dev server
                return "npm run dev"
              elseif parsed and parsed.scripts and parsed.scripts.start then
                return "npm start"
              end
            end
          end
          return nil
        end
      },
      {
        name = "test",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          if project_info and project_info.type == "nodejs" then
            return "npm test"
          end
          return nil
        end
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
  
  ["systems-programming"] = {
    description = "Systems programming layout for Rust, C/C++",
    tabs = {
      {
        name = "build",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          if project_info and project_info.type == "rust" then
            return "cargo watch -x run"
          elseif project_info and project_info.type == "c_cpp" then
            return "make"
          end
          return nil
        end
      },
      {
        name = "test",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          if project_info and project_info.type == "rust" then
            return "cargo watch -x test"
          end
          return nil
        end
      },
      {
        name = "docs",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          if project_info and project_info.type == "rust" then
            return "cargo doc --open"
          end
          return nil
        end
      }
    }
  },
  
  ["backend-service"] = {
    description = "Backend service layout for Go, Python APIs",
    tabs = {
      {
        name = "serve",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          if project_info and project_info.type == "golang" then
            return "go run main.go"
          elseif project_info and project_info.type == "python" then
            return "python main.py"
          end
          return nil
        end
      },
      {
        name = "test",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          if project_info and project_info.type == "golang" then
            return "go test -v ./..."
          elseif project_info and project_info.type == "python" then
            return "python -m pytest"
          end
          return nil
        end
      },
      {
        name = "logs",
        cwd_relative = true,
        panes = {
          {
            command = "tail -f *.log",
            split = nil,
            cwd_relative = true
          }
        }
      }
    }
  },
  
  ["data-science"] = {
    description = "Data science layout for Python, Jupyter, analysis",
    tabs = {
      {
        name = "jupyter",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        },
        post_create = function(tab, project_info)
          return "jupyter lab"
        end
      },
      {
        name = "analysis",
        cwd_relative = true,
        panes = {
          {
            command = "python",
            split = nil,
            cwd_relative = true
          }
        }
      },
      {
        name = "data",
        cwd_relative = true,
        panes = {
          {
            command = nil,
            split = nil,
            cwd_relative = true
          }
        }
      }
    }
  },
  
  ["general-development"] = {
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
  }
}

-- Initialize the layouts module
function M.init(user_config)
  config = user_config
end

-- Apply a layout to the current workspace
function M.apply_layout(layout_name, project_info, window, pane)
  local layout = layout_templates[layout_name]
  if not layout then
    wezterm.log_error("Layout not found: " .. layout_name)
    return false
  end
  
  local workspace_name = window:active_workspace()
  local project_path = project_info and project_info.path or pane:get_current_working_dir().file_path
  
  -- Apply each tab in the layout
  for i, tab_config in ipairs(layout.tabs) do
    local tab = nil
    
    if i == 1 then
      -- Use the current tab for the first tab
      tab = window:active_tab()
      if tab_config.name then
        tab:set_title(tab_config.name)
      end
    else
      -- Create new tabs for additional tabs
      tab = window:spawn_tab {
        cwd = tab_config.cwd_relative and project_path or nil,
      }
      if tab_config.name then
        tab:set_title(tab_config.name)
      end
    end
    
    -- Apply pane configuration
    M.apply_pane_layout(tab, tab_config.panes, project_path, project_info)
    
    -- Execute post-create commands
    if tab_config.post_create then
      local command = tab_config.post_create(tab, project_info)
      if command then
        -- Send the command to the first pane of the tab
        local first_pane = tab:panes()[1]
        if first_pane then
          first_pane:send_text(command .. "\n")
        end
      end
    end
  end
  
  -- Switch back to the first tab
  window:perform_action(wezterm.action.ActivateTab(0), pane)
  
  return true
end

-- Apply pane layout within a tab
function M.apply_pane_layout(tab, panes_config, project_path, project_info)
  if not panes_config or #panes_config == 0 then
    return
  end
  
  -- The first pane already exists (the tab's default pane)
  local current_pane = tab:active_pane()
  
  -- Set working directory for the first pane
  if panes_config[1].cwd_relative and project_path then
    current_pane:send_text("cd '" .. project_path .. "'\n")
  end
  
  -- Execute command for the first pane
  if panes_config[1].command then
    current_pane:send_text(panes_config[1].command .. "\n")
  end
  
  -- Create additional panes
  for i = 2, #panes_config do
    local pane_config = panes_config[i]
    local split_direction = pane_config.split
    
    local new_pane = nil
    if split_direction == "horizontal" then
      new_pane = current_pane:split {
        direction = "Right",
        size = 0.5,
        cwd = pane_config.cwd_relative and project_path or nil,
      }
    elseif split_direction == "vertical" then
      new_pane = current_pane:split {
        direction = "Bottom",
        size = 0.5,
        cwd = pane_config.cwd_relative and project_path or nil,
      }
    else
      -- Default to vertical split
      new_pane = current_pane:split {
        direction = "Bottom",
        size = 0.5,
        cwd = pane_config.cwd_relative and project_path or nil,
      }
    end
    
    if new_pane then
      -- Set working directory
      if pane_config.cwd_relative and project_path then
        new_pane:send_text("cd '" .. project_path .. "'\n")
      end
      
      -- Execute command
      if pane_config.command then
        new_pane:send_text(pane_config.command .. "\n")
      end
      
      current_pane = new_pane
    end
  end
end

-- Get available layouts
function M.get_available_layouts()
  local layouts = {}
  for name, layout in pairs(layout_templates) do
    table.insert(layouts, {
      name = name,
      description = layout.description,
      tabs_count = #layout.tabs
    })
  end
  
  table.sort(layouts, function(a, b) return a.name < b.name end)
  return layouts
end

-- Add a custom layout
function M.add_layout(name, layout_config)
  layout_templates[name] = layout_config
end

-- Get layout by name
function M.get_layout(name)
  return layout_templates[name]
end

-- Remove a layout
function M.remove_layout(name)
  layout_templates[name] = nil
end

-- Validate a layout configuration
function M.validate_layout(layout_config)
  if not layout_config.tabs or #layout_config.tabs == 0 then
    return false, "Layout must have at least one tab"
  end
  
  for i, tab in ipairs(layout_config.tabs) do
    if not tab.name then
      return false, "Tab " .. i .. " must have a name"
    end
    
    if not tab.panes or #tab.panes == 0 then
      return false, "Tab " .. tab.name .. " must have at least one pane"
    end
  end
  
  return true, "Layout is valid"
end

-- Create a layout from current workspace
function M.capture_current_layout(window)
  local layout = {
    description = "Captured layout from " .. window:active_workspace(),
    tabs = {}
  }
  
  for i, tab in ipairs(window:tabs()) do
    local tab_config = {
      name = tab:tab_title() or ("Tab " .. i),
      cwd_relative = true,
      panes = {}
    }
    
    for j, pane in ipairs(tab:panes()) do
      local pane_config = {
        command = nil, -- Can't capture running commands
        split = j > 1 and "vertical" or nil, -- Simplified split detection
        cwd_relative = true
      }
      table.insert(tab_config.panes, pane_config)
    end
    
    table.insert(layout.tabs, tab_config)
  end
  
  return layout
end

return M 