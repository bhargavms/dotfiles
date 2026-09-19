# Advanced WezTerm Workspace Management

A comprehensive workspace management system for WezTerm that transforms it from a basic terminal multiplexer into an intelligent project workspace manager with automatic project detection, smart switching, and persistent layouts.

## 🚀 Features

### **Project Context Isolation** 🏗️
- Separate terminal environments for different projects (web app, mobile app, infrastructure)
- Each workspace maintains its own working directories, environment variables, and terminal sessions
- Prevent command history and context bleeding between unrelated projects

### **Rapid Project Switching** ⚡
- Quick fuzzy-finder interface to jump between project workspaces
- Smart workspace detection based on git repositories or project markers
- Restore exact terminal layout and working directories when switching contexts

### **Persistent Development Sessions** 💾
- Save and restore complex terminal layouts (multiple panes, tabs, running processes)
- Resume exactly where you left off when returning to a project
- Survive system reboots and WezTerm restarts

### **Intelligent Project Detection** 🔍
- Automatically detects project types based on common markers:
  - Node.js: `package.json`
  - Rust: `Cargo.toml`
  - Go: `go.mod`
  - Python: `requirements.txt`, `setup.py`, `pyproject.toml`
  - Java: `pom.xml`
  - C/C++: `Makefile`
  - Git: `.git` directory

### **Pre-configured Layouts** 🎨
- **Web Development**: Dev server, testing, and git tabs
- **Systems Programming**: Build, test, and documentation for Rust/C++
- **Backend Service**: Server, testing, and logs for Go/Python APIs
- **Data Science**: Jupyter, analysis, and data exploration
- **General Development**: Flexible layout for any project type

## 📁 Directory Structure

```
~/.config/wezterm/
├── wezterm.lua              # Main configuration with workspace integration
├── workspaces/
│   ├── manager.lua          # Core workspace logic and state management
│   ├── projects.lua         # Project detection and discovery
│   ├── layouts.lua          # Layout templates and application
│   └── switcher.lua         # Workspace switcher UI and navigation
├── projects/
│   ├── web-app.lua          # Example: Custom web app configuration
│   └── default.lua          # Default workspace template
└── workspace-states/        # Persistent workspace state storage
    ├── my-project.json      # Saved state for specific workspaces
    └── ...
```

## 🎯 Quick Start

The system is already configured and ready to use! Here are the key bindings:

### **Essential Keybindings**

| Key Combination | Action | Description |
|-----------------|--------|-------------|
| `Ctrl+A` | Leader Key | Press before any workspace command |
| `Leader + w` | Switch Workspace | Fuzzy finder to switch between workspaces |
| `Leader + W` | Create Workspace | Create a new workspace with custom name |
| `Leader + p` | Quick Project | Find and switch to projects automatically |
| `Leader + r` | Rename Workspace | Rename the current workspace |
| `Leader + i` | Workspace Info | Show detailed workspace information |
| `Leader + s` | Save State | Save current workspace layout and state |

### **Standard Terminal Operations**

| Key Combination | Action |
|-----------------|--------|
| `Leader + c` | New Tab |
| `Leader + x` | Close Pane |
| `Leader + v` | Split Horizontal |
| `Leader + h` | Split Vertical |

## 🔧 Configuration

### **Workspace Settings**

The system can be customized in `wezterm.lua`:

```lua
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
```

### **Custom Project Configurations**

Create project-specific configurations in the `projects/` directory:

```lua
-- projects/my-custom-project.lua
local M = {}

M.config = {
  name = "my-custom-project",
  description = "Custom project workspace",
  
  layout = {
    tabs = {
      {
        name = "dev",
        cwd_relative = true,
        panes = { { command = nil, split = nil, cwd_relative = true } },
        post_create = function(tab, project_info)
          return "npm run dev"  -- Auto-start dev server
        end
      },
      -- Add more tabs as needed
    }
  },
  
  env = {
    NODE_ENV = "development",
    DEBUG = "app:*"
  },
  
  startup_commands = {
    "npm install",
    "git fetch"
  }
}

function M.apply(window, pane, project_info)
  -- Custom setup logic
end

return M
```

## 🎨 Available Layouts

### **Web Development Layout**
- **dev**: Main development with auto-starting dev server
- **test**: Testing environment with watch mode
- **git**: Git operations and status

### **Systems Programming Layout**
- **build**: Compilation and build watching (Rust: `cargo watch -x run`)
- **test**: Test execution and watching
- **docs**: Documentation generation

### **Backend Service Layout**
- **serve**: Server execution and monitoring
- **test**: API testing and validation
- **logs**: Log monitoring and debugging

### **Data Science Layout**
- **jupyter**: Jupyter Lab environment
- **analysis**: Python REPL for quick analysis
- **data**: Data exploration and file management

### **General Development Layout**
- **main**: Primary development pane
- **tools**: Split panes for utilities
- **git**: Version control operations

## 🔍 Project Discovery

The system automatically scans common project directories:

- `~/Projects`
- `~/Code`
- `~/Development`
- `~/work`
- `~/src`
- `~/repos`
- `/usr/local/src`
- `/opt`

Projects are detected by the presence of these markers:
- `.git` (Git repository)
- `package.json` (Node.js)
- `Cargo.toml` (Rust)
- `go.mod` (Go)
- `requirements.txt`, `setup.py`, `pyproject.toml` (Python)
- `pom.xml` (Java)
- `Makefile` (C/C++)

## 💾 State Persistence

Workspace states are automatically saved to `~/.config/wezterm/workspace-states/` and include:

- Tab names and configurations
- Pane layouts and splits
- Working directories
- Project information
- Creation and access timestamps

States are restored when:
- Switching back to a workspace
- Restarting WezTerm (if `restore_on_startup` is enabled)
- Manually loading a saved state

## 🚀 Usage Examples

### **Create a New Project Workspace**

1. Navigate to your project directory in any terminal
2. If the directory contains project markers, a workspace will be created automatically
3. Or manually create one with `Leader + W`

### **Switch Between Projects**

1. Press `Leader + w` to open the workspace switcher
2. Type to filter workspaces (fuzzy search)
3. Press Enter to switch
4. Recent workspaces are prioritized

### **Quick Project Discovery**

1. Press `Leader + p` to open project finder
2. Browse all detected projects in common directories
3. Select a project to create/switch to its workspace

### **Save and Restore Sessions**

1. Set up your ideal workspace layout
2. Press `Leader + s` to save the current state
3. State will be automatically restored when returning to the workspace

## 🔧 Troubleshooting

### **Workspace Not Auto-Created**

- Ensure your project directory contains recognized markers
- Check that `auto_create = true` in configuration
- Verify the directory is accessible and readable

### **Layout Not Applied**

- Check that the layout name exists in the layouts module
- Verify project type detection is working correctly
- Look for error messages in WezTerm logs

### **State Not Persisting**

- Ensure `save_state = true` in configuration
- Check that `~/.config/wezterm/workspace-states/` directory exists and is writable
- Verify JSON files are being created in the states directory

### **Keybindings Not Working**

- Ensure `Leader` key (Ctrl+A) is pressed first
- Check for conflicts with other terminal applications
- Verify WezTerm version supports required features

## 🛠️ Extending the System

### **Add Custom Layout**

```lua
local layouts = require('workspaces.layouts')

layouts.add_layout("my-layout", {
  description = "My custom layout",
  tabs = {
    {
      name = "main",
      cwd_relative = true,
      panes = { { command = nil, split = nil, cwd_relative = true } }
    }
  }
})
```

### **Add Project Detection Pattern**

```lua
local projects = require('workspaces.projects')

projects.add_project_pattern({
  markers = { "composer.json" },
  type = "php",
  name_from = "composer.json",
  parser = function(path)
    -- Custom parsing logic
    return "my-php-project"
  end
})
```

## 📋 Requirements

- WezTerm (latest version recommended)
- Lua 5.4+ (included with WezTerm)
- macOS, Linux, or Windows with WSL
- Git (for project detection)

## 🤝 Contributing

This workspace management system is designed to be extensible. You can:

1. Add new layout templates
2. Create project-specific configurations
3. Extend project detection patterns
4. Customize keybindings and behaviors

## 📄 License

This configuration is provided as-is for personal and educational use. Feel free to modify and distribute according to your needs.

---

**Happy coding with your intelligent WezTerm workspace management!** 🎉 