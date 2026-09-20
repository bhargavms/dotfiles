local wezterm = require 'wezterm'

local M = {}

-- Configuration will be set by manager
local config = {}

-- Recent workspaces tracking
local recent_workspaces = {}
local max_recent = 10

-- Initialize the switcher module
function M.init(user_config)
  config = user_config
end

-- Show the workspace switcher
function M.show(window, pane, callback)
  local workspaces = wezterm.mux.get_workspace_names()
  local current_workspace = window:active_workspace()

  if #workspaces == 0 then
    window:toast_notification('WezTerm', 'No workspaces available', nil, 2000)
    return
  end

  -- Build choices for the InputSelector
  local choices = {}

  -- Add current workspace first (marked as current)
  for _, workspace in ipairs(workspaces) do
    if workspace == current_workspace then
      table.insert(choices, {
        id = workspace,
        label = "• " .. workspace .. " (current)",
      })
      break
    end
  end

  -- Add recent workspaces next
  for _, workspace in ipairs(recent_workspaces) do
    if workspace ~= current_workspace then
      -- Check if workspace still exists
      local exists = false
      for _, w in ipairs(workspaces) do
        if w == workspace then
          exists = true
          break
        end
      end

      if exists then
        table.insert(choices, {
          id = workspace,
          label = "↻ " .. workspace .. " (recent)",
        })
      end
    end
  end

  -- Add remaining workspaces
  for _, workspace in ipairs(workspaces) do
    if workspace ~= current_workspace and not M.is_in_recent(workspace) then
      table.insert(choices, {
        id = workspace,
        label = "  " .. workspace,
      })
    end
  end

  -- Show the InputSelector
  window:perform_action(
    wezterm.action.InputSelector {
      action = wezterm.action_callback(function(window, pane, id, label)
        if id and callback then
          M.add_to_recent(id)
          callback(id)
        end
      end),
      title = 'Switch to Workspace',
      choices = choices,
      fuzzy = true,
      description = 'Type to filter workspaces. Press Enter to switch, Escape to cancel.',
    },
    pane
  )
end

-- Check if workspace is in recent list
function M.is_in_recent(workspace)
  for _, recent in ipairs(recent_workspaces) do
    if recent == workspace then
      return true
    end
  end
  return false
end

-- Add workspace to recent list
function M.add_to_recent(workspace)
  -- Remove if already exists
  for i, recent in ipairs(recent_workspaces) do
    if recent == workspace then
      table.remove(recent_workspaces, i)
      break
    end
  end

  -- Add to front
  table.insert(recent_workspaces, 1, workspace)

  -- Limit size
  if #recent_workspaces > max_recent then
    table.remove(recent_workspaces, #recent_workspaces)
  end
end

-- Show workspace info selector
function M.show_workspace_info(window, pane)
  local workspaces = wezterm.mux.get_workspace_names()
  local current_workspace = window:active_workspace()

  local choices = {}
  for _, workspace in ipairs(workspaces) do
    local label = workspace
    if workspace == current_workspace then
      label = "• " .. workspace .. " (current)"
    end

    table.insert(choices, {
      id = workspace,
      label = label,
    })
  end

  window:perform_action(
    wezterm.action.InputSelector {
      action = wezterm.action_callback(function(window, pane, id, label)
        if id then
          M.show_detailed_info(id, window)
        end
      end),
      title = 'Workspace Information',
      choices = choices,
      fuzzy = true,
    },
    pane
  )
end

-- Show detailed information about a workspace
function M.show_detailed_info(workspace_name, window)
  local info = "Workspace: " .. workspace_name .. "\n"

  -- Get workspace tabs and panes count
  local saved_workspace = window:active_workspace()

  -- Switch temporarily to get info (this is not ideal but necessary)
  window:perform_action(
    wezterm.action.SwitchToWorkspace {
      name = workspace_name,
    },
    window:active_pane()
  )

  local tabs = window:tabs()
  info = info .. "Tabs: " .. #tabs .. "\n"

  local total_panes = 0
  for _, tab in ipairs(tabs) do
    total_panes = total_panes + #tab:panes()
  end
  info = info .. "Total Panes: " .. total_panes .. "\n"

  -- Switch back
  if saved_workspace ~= workspace_name then
    window:perform_action(
      wezterm.action.SwitchToWorkspace {
        name = saved_workspace,
      },
      window:active_pane()
    )
  end

  window:toast_notification('Workspace Info', info, nil, 5000)
end

-- Show quick workspace actions
function M.show_workspace_actions(window, pane)
  local current_workspace = window:active_workspace()

  local choices = {
    {
      id = "switch",
      label = "🔄 Switch Workspace",
    },
    {
      id = "create",
      label = "➕ Create New Workspace",
    },
    {
      id = "info",
      label = "ℹ️  Show Workspace Info",
    },
    {
      id = "save",
      label = "💾 Save Current State",
    },
    {
      id = "layouts",
      label = "🎨 Browse Layouts",
    },
    {
      id = "projects",
      label = "📁 Quick Project Switch",
    }
  }

  window:perform_action(
    wezterm.action.InputSelector {
      action = wezterm.action_callback(function(window, pane, id, label)
        if id == "switch" then
          M.show(window, pane, function(selected_workspace)
            if selected_workspace then
              window:perform_action(
                wezterm.action.SwitchToWorkspace {
                  name = selected_workspace,
                },
                pane
              )
            end
          end)
        elseif id == "create" then
          M.create_new_workspace(window, pane)
        elseif id == "info" then
          M.show_workspace_info(window, pane)
        elseif id == "save" then
          window:toast_notification('WezTerm', 'Workspace state saved: ' .. current_workspace, nil, 2000)
        elseif id == "layouts" then
          M.show_layout_selector(window, pane)
        elseif id == "projects" then
          -- This would call the project switcher
          window:toast_notification('WezTerm', 'Project switcher would be shown here', nil, 2000)
        end
      end),
      title = 'Workspace Actions',
      choices = choices,
      fuzzy = false,
    },
    pane
  )
end

-- Create new workspace with input
function M.create_new_workspace(window, pane)
  window:perform_action(
    wezterm.action.PromptInputLine {
      description = 'Enter name for new workspace:',
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= '' then
          local workspace_name = line:gsub("[^%w%-_]", "-"):lower()

          window:perform_action(
            wezterm.action.SwitchToWorkspace {
              name = workspace_name,
            },
            pane
          )

          M.add_to_recent(workspace_name)
          window:toast_notification('WezTerm', 'Created workspace: ' .. workspace_name, nil, 2000)
        end
      end),
    },
    pane
  )
end

-- Show layout selector
function M.show_layout_selector(window, pane)
  local layouts = require('workspaces.layouts')
  local available_layouts = layouts.get_available_layouts()

  local choices = {}
  for _, layout in ipairs(available_layouts) do
    table.insert(choices, {
      id = layout.name,
      label = layout.name .. " - " .. layout.description .. " (" .. layout.tabs_count .. " tabs)",
    })
  end

  window:perform_action(
    wezterm.action.InputSelector {
      action = wezterm.action_callback(function(window, pane, id, label)
        if id then
          -- Apply the selected layout to current workspace
          local current_workspace = window:active_workspace()
          layouts.apply_layout(id, nil, window, pane)
          window:toast_notification('WezTerm', 'Applied layout: ' .. id, nil, 2000)
        end
      end),
      title = 'Select Layout to Apply',
      choices = choices,
      fuzzy = true,
    },
    pane
  )
end

-- Get recent workspaces list
function M.get_recent_workspaces()
  return recent_workspaces
end

-- Clear recent workspaces
function M.clear_recent()
  recent_workspaces = {}
end

-- Set max recent workspaces to track
function M.set_max_recent(max)
  max_recent = max

  -- Trim existing list if necessary
  while #recent_workspaces > max_recent do
    table.remove(recent_workspaces, #recent_workspaces)
  end
end

return M
