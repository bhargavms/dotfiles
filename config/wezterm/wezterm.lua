local wezterm = require 'wezterm'

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

config.default_prog = { '/bin/zsh', '-l' }
config.selection_word_boundary = ' \t\n{}[]()"\'`,;:@│┃*…$'
config.debug_key_events = false
config.color_scheme = scheme_for_appearance(get_appearance())
config.font = wezterm.font '0xProto Nerd Font'
config.audible_bell = 'Disabled'
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.font_size = 18.0
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false
config.use_dead_keys = false

-- Pane focus (vim-style)
config.keys = {
  {
    key = 'h',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'j',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  {
    key = 'k',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'l',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Right',
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
