local wezterm = require 'wezterm'

-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return 'Dark'
end

function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'CGA'
  else
    return 'GruvboxLight'
  end
end

local config = wezterm.config_builder()

-- Load workspace management system
local workspaces = require('workspaces.manager')

-- Basic configuration
config.default_prog = { '/bin/zsh', '-l' }
config.selection_word_boundary = ' \t\n{}[]()"\'`,;:@│┃*…$'
config.debug_key_events = true
config.color_scheme = scheme_for_appearance(get_appearance())
config.font = wezterm.font '0xProto Nerd Font'
config.audible_bell = 'Disabled'
config.hide_tab_bar_if_only_one_tab = true
config.font_size = 18.0
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Remap Caps Lock to Ctrl (only within WezTerm)
config.use_dead_keys = false

-- Leader key for workspace management  
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

-- Initialize workspace management
workspaces.setup({
  -- Auto-create workspaces when navigating to projects
  auto_create = true,
  
  -- Project detection patterns
  project_markers = { ".git", "package.json", "Cargo.toml", "go.mod", "Makefile", "requirements.txt", "pom.xml" },
  
  -- Default layouts by project type
  layouts = {
    nodejs = "web-development",
    rust = "systems-programming",
    golang = "backend-service",
    python = "data-science",
    default = "general-development"
  },
  
  -- Workspace persistence
  save_state = true,
  restore_on_startup = true,
  
  -- Smart features
  auto_cd_to_project_root = true,
  restore_previous_session = true
})

-- Key bindings for workspace management
config.keys = {
  -- Workspace switching (LEADER + w)
  {
    key = 'w',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      workspaces.show_switcher(window, pane)
    end),
  },
  
  -- Create new workspace (LEADER + W)
  {
    key = 'W',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      workspaces.create_new(window, pane)
    end),
  },
  
  -- Rename current workspace (LEADER + r)
  {
    key = 'r',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      workspaces.rename_workspace(window, pane)
    end),
  },
  
  -- Show workspace info (LEADER + i)
  {
    key = 'i',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      workspaces.show_info(window, pane)
    end),
  },
  
  -- Quick project navigation (LEADER + p)
  {
    key = 'p',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      workspaces.quick_project_switch(window, pane)
    end),
  },
  
  -- Save workspace state (LEADER + s)
  {
    key = 's',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      workspaces.save_current_state(window, pane)
    end),
  },
  
  -- Standard tab/pane management
  {
    key = 'c',
    mods = 'LEADER',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = 'x',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  {
    key = 'v',
    mods = 'LEADER',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'h',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
}



return config
