# WezTerm workspace helpers

Modular WezTerm config with workspace switching, project discovery, layout templates, optional per-project Lua configs, and AeroSpace bottom-dock integration (see `wezterm.lua`).

## Features (actual behavior)

- **Workspace switcher** — `Leader + w` fuzzy list with current/recent ordering
- **Manual project workspaces** — `Leader + p` scans common dirs and creates/switches by detected project
- **Layout templates** — tabs/panes with optional `post_create` commands (off by default)
- **Per-project config** — `projects/<sanitized-project-name>.lua` with an `apply(window, pane, project_info)` hook
- **State files** — `Leader + s` saves tab titles, pane CWDs, and metadata to `workspace-states/*.json`; partial restore when you switch back (extra tabs + `cd`, not split geometry)
- **AeroSpace dock** — reads `~/.config/aerospace/.wezterm-dock` and sizes the window as a bottom strip

## Not supported / limitations

- **Workspace rename** (`Leader + r`) — WezTerm has no rename API; shows a toast only
- **Full session restore** — running processes and pane splits are not saved
- **Silent auto-create** — disabled; projects are not auto-switched when you `cd` into a repo
- **`projects/*.lua` keybindings / status** — only `apply()` (and optional `config`) is wired today

## Directory layout

```
~/.config/wezterm/
├── wezterm.lua
├── workspaces/
│   ├── manager.lua
│   ├── projects.lua
│   ├── layouts.lua
│   └── switcher.lua
├── projects/
│   ├── default.lua          # example template (not auto-loaded by name)
│   └── web-app.lua          # loaded when detected project name is web-app
└── workspace-states/        # JSON snapshots from Leader + s
```

## Keybindings

| Keys | Action |
|------|--------|
| `Ctrl+A` | Leader |
| `Leader + w` | Switch workspace |
| `Leader + W` | New workspace (prompt) |
| `Leader + p` | Pick project → workspace |
| `Leader + r` | Rename (unsupported; toast) |
| `Leader + i` | Workspace info toast |
| `Leader + s` | Save state to JSON |
| `Leader + c/x/v/h` | Tab / close pane / splits |

## Configuration (`wezterm.lua`)

```lua
workspaces.setup({
  auto_create = false,
  run_post_create_commands = false,  -- set true to auto-run npm/cargo/jupyter hooks in layouts

  project_markers = { ".git", "package.json", "Cargo.toml", "go.mod", "Makefile", "requirements.txt", "pom.xml" },

  layouts = {
    nodejs = "web-development",
    rust = "systems-programming",
    golang = "backend-service",
    python = "data-science",
    default = "general-development",
  },

  save_state = true,
  restore_on_startup = true,  -- loads JSON metadata into memory on start
  auto_cd_to_project_root = true,  -- reserved / not fully wired
  restore_previous_session = true,  -- reserved / not fully wired
})
```

## Project discovery paths

Scanned (max depth 2) for `Leader + p`:

- `~/github`, `~/Projects`, `~/Code`, `~/Development`, `~/work`, `~/src`, `~/repos`
- `/usr/local/src`, `/opt`

## Custom project file

Create `projects/my-app.lua` where `my-app` matches the **sanitized** detected name (lowercase, non-alphanumeric → `-`):

```lua
local wezterm = require 'wezterm'
local M = {}

function M.apply(window, pane, project_info)
  local layouts = require('workspaces.layouts')
  layouts.apply_layout('web-development', project_info, window, pane)
end

return M
```

If `apply` is missing, the type-based layout from `layouts` in `wezterm.lua` is used instead.

## Requirements

- WezTerm with Lua config support
- macOS AeroSpace scripts optional (dock integration)
