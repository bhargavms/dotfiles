local wezterm = require 'wezterm'
local projects = require('workspaces.projects')
local layouts = require('workspaces.layouts')
local switcher = require('workspaces.switcher')
local io = require 'io'
local os = require 'os'

local M = {}

-- Configuration defaults
local config = {
  auto_create = true,
  project_markers = { ".git", "package.json", "Cargo.toml", "go.mod", "Makefile", "requirements.txt", "pom.xml" },
  layouts = {
    nodejs = "web-development",
    rust = "systems-programming",
    golang = "backend-service",
    python = "data-science",
    default = "general-development"
  },
  save_state = true,
  restore_on_startup = true,
  auto_cd_to_project_root = true,
  restore_previous_session = true
}

-- State tracking
local workspace_states = {}
local current_workspace = nil

-- Setup function called from main config
function M.setup(user_config)
  if user_config then
    for k, v in pairs(user_config) do
      config[k] = v
    end
  end
  
  -- Initialize components
  projects.init(config)
  layouts.init(config)
  switcher.init(config)
  
  -- Restore workspace states if enabled
  if config.restore_on_startup then
    M.restore_all_states()
  end
  
  -- Set up auto workspace creation if enabled
  if config.auto_create then
    M.setup_auto_creation()
  end
end

-- Auto workspace creation based on project detection
function M.setup_auto_creation()
  wezterm.on('update-status', function(window, pane)
    local cwd = pane:get_current_working_dir()
    if cwd then
      local project_info = projects.detect_project(cwd.file_path)
      if project_info and not M.workspace_exists(project_info.name) then
        M.create_project_workspace(project_info, window, pane)
      end
    end
  end)
end

-- Check if a workspace exists
function M.workspace_exists(name)
  local workspaces = wezterm.mux.get_workspace_names()
  for _, workspace in ipairs(workspaces) do
    if workspace == name then
      return true
    end
  end
  return false
end

-- Create a new project workspace
function M.create_project_workspace(project_info, window, pane)
  local workspace_name = project_info.name
  local project_type = project_info.type or 'default'
  
  -- Switch to new workspace
  window:perform_action(
    wezterm.action.SwitchToWorkspace {
      name = workspace_name,
    },
    pane
  )
  
  -- Apply project layout
  local layout_name = config.layouts[project_type] or config.layouts.default
  layouts.apply_layout(layout_name, project_info, window, pane)
  
  -- Save workspace state
  workspace_states[workspace_name] = {
    project_info = project_info,
    layout = layout_name,
    created_at = os.time(),
    last_accessed = os.time()
  }
  
  current_workspace = workspace_name
  M.save_workspace_state(workspace_name)
end

-- Show workspace switcher
function M.show_switcher(window, pane)
  switcher.show(window, pane, function(selected_workspace)
    if selected_workspace then
      M.switch_to_workspace(selected_workspace, window, pane)
    end
  end)
end

-- Switch to a specific workspace
function M.switch_to_workspace(workspace_name, window, pane)
  window:perform_action(
    wezterm.action.SwitchToWorkspace {
      name = workspace_name,
    },
    pane
  )
  
  current_workspace = workspace_name
  
  -- Update last accessed time
  if workspace_states[workspace_name] then
    workspace_states[workspace_name].last_accessed = os.time()
  end
  
  -- Restore workspace state if available
  M.restore_workspace_state(workspace_name)
end

-- Create a new workspace manually
function M.create_new(window, pane)
  window:perform_action(
    wezterm.action.PromptInputLine {
      description = 'Enter name for new workspace:',
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= '' then
          local workspace_name = line
          
          window:perform_action(
            wezterm.action.SwitchToWorkspace {
              name = workspace_name,
            },
            pane
          )
          
          -- Initialize with default layout
          layouts.apply_layout(config.layouts.default, nil, window, pane)
          
          workspace_states[workspace_name] = {
            project_info = nil,
            layout = config.layouts.default,
            created_at = os.time(),
            last_accessed = os.time()
          }
          
          current_workspace = workspace_name
          M.save_workspace_state(workspace_name)
        end
      end),
    },
    pane
  )
end

-- Rename current workspace
function M.rename_workspace(window, pane)
  local current = window:active_workspace()
  
  window:perform_action(
    wezterm.action.PromptInputLine {
      description = 'Enter new name for workspace "' .. current .. '":',
      initial_value = current,
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= '' and line ~= current then
          -- Note: WezTerm doesn't support renaming workspaces directly
          -- This is a limitation we'll document
          window:toast_notification('WezTerm', 'Workspace renaming not yet supported by WezTerm', nil, 4000)
        end
      end),
    },
    pane
  )
end

-- Show workspace information
function M.show_info(window, pane)
  local current = window:active_workspace()
  local state = workspace_states[current]
  local info = "Workspace: " .. current .. "\n"
  
  if state then
    if state.project_info then
      info = info .. "Project: " .. (state.project_info.name or "Unknown") .. "\n"
      info = info .. "Type: " .. (state.project_info.type or "Unknown") .. "\n"
      info = info .. "Path: " .. (state.project_info.path or "Unknown") .. "\n"
    end
    info = info .. "Layout: " .. (state.layout or "Unknown") .. "\n"
    info = info .. "Created: " .. os.date("%Y-%m-%d %H:%M:%S", state.created_at) .. "\n"
    info = info .. "Last Accessed: " .. os.date("%Y-%m-%d %H:%M:%S", state.last_accessed) .. "\n"
  end
  
  window:toast_notification('Workspace Info', info, nil, 8000)
end

-- Quick project switch using fuzzy finder
function M.quick_project_switch(window, pane)
  local project_dirs = projects.find_all_projects()
  
  local choices = {}
  for _, project in ipairs(project_dirs) do
    table.insert(choices, {
      id = project.path,
      label = project.name .. " (" .. project.type .. ") - " .. project.path,
    })
  end
  
  window:perform_action(
    wezterm.action.InputSelector {
      action = wezterm.action_callback(function(window, pane, id, label)
        if id then
          local project_info = projects.detect_project(id)
          if project_info then
            M.create_project_workspace(project_info, window, pane)
          end
        end
      end),
      title = 'Select Project',
      choices = choices,
      fuzzy = true,
    },
    pane
  )
end

-- Save current workspace state
function M.save_current_state(window, pane)
  local workspace_name = window:active_workspace()
  M.save_workspace_state(workspace_name)
  window:toast_notification('WezTerm', 'Workspace state saved: ' .. workspace_name, nil, 2000)
end

-- Save workspace state to file
function M.save_workspace_state(workspace_name)
  if not config.save_state then
    return
  end
  
  local state_file = wezterm.config_dir .. "/workspace-states/" .. workspace_name .. ".json"
  local state = workspace_states[workspace_name]
  
  if state then
    -- Add current tab/pane information
    state.tabs = M.get_current_tab_layout()
    
    local file = io.open(state_file, "w")
    if file then
      file:write(wezterm.json_encode(state))
      file:close()
    end
  end
end

-- Restore workspace state from file
function M.restore_workspace_state(workspace_name)
  if not config.save_state then
    return
  end
  
  local state_file = wezterm.config_dir .. "/workspace-states/" .. workspace_name .. ".json"
  local file = io.open(state_file, "r")
  
  if file then
    local content = file:read("*all")
    file:close()
    
    local state = wezterm.json_parse(content)
    if state then
      workspace_states[workspace_name] = state
      -- Restore tab layout if available
      if state.tabs then
        M.restore_tab_layout(state.tabs)
      end
    end
  end
end

-- Restore all workspace states on startup
function M.restore_all_states()
  local state_dir = wezterm.config_dir .. "/workspace-states"
  
  -- Create state directory if it doesn't exist
  os.execute("mkdir -p " .. state_dir)
  
  -- This is a simplified version - full implementation would scan directory
  -- WezTerm Lua has limited file system access
end

-- Get current tab layout (simplified)
function M.get_current_tab_layout()
  -- This would capture current tab/pane structure
  -- Simplified for this implementation
  return {
    timestamp = os.time(),
    note = "Tab layout capture would be implemented here"
  }
end

-- Restore tab layout (simplified)
function M.restore_tab_layout(layout_data)
  -- This would restore the exact tab/pane structure
  -- Simplified for this implementation
end

return M 