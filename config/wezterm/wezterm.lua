local wezterm = require 'wezterm'

-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return 'Dark'
end

local function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'rose-pine-moon'
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
config.debug_key_events = false
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
  -- Use Leader + p to create/switch project workspaces (no silent auto-create)
  auto_create = false,

  -- Layout templates define post_create hooks; leave off unless you want auto npm/cargo/jupyter
  run_post_create_commands = false,

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

-- AeroSpace bottom dock: shell writes point geometry; we convert to WezTerm pixels.
local dock_file = os.getenv('HOME') .. '/.config/aerospace/.wezterm-dock'
local last_applied = ''

local function apply_dock(window)
  local f = io.open(dock_file, 'r')
  if not f then
    return
  end
  local data = f:read('*a')
  f:close()
  if data:match('^full') then
    return
  end
  local x, y, w, h = data:match('^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)')
  if not x then
    return
  end
  x, y, w, h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)

  local gui = window
  if window.gui_window then
    gui = window:gui_window()
  end
  if not gui then
    return
  end

  local screens = wezterm.gui.screens()
  local screen = screens.active or screens.main
  local scale = (screen and screen.width or w) / w
  local gap = h * scale
  local chrome = 28 * scale
  local inner_h = math.max(80, gap - chrome)
  local px = x * scale
  local py = y * scale
  local pw = w * scale

  local dims = gui:get_dimensions()
  if dims and dims.is_full_screen then
    return
  end
  if last_applied == data and dims and math.abs(dims.pixel_height - inner_h) < 48 then
    return
  end
  last_applied = data
  gui:set_inner_size(pw, inner_h)
  gui:set_position(px, py)
end

wezterm.on('update-status', apply_dock)
wezterm.on('window-focus-changed', apply_dock)

return config
