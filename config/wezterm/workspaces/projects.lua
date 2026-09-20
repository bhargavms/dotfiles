local wezterm = require 'wezterm'
local io = require 'io'
local os = require 'os'

local M = {}

-- Configuration will be set by manager
local config = {}

-- Project type detection patterns
local project_patterns = {
  {
    markers = { "package.json" },
    type = "nodejs",
    name_from = "package.json",
    parser = function(path)
      local package_file = path .. "/package.json"
      local file = io.open(package_file, "r")
      if file then
        local content = file:read("*all")
        file:close()
        local parsed = wezterm.json_parse(content)
        if parsed and parsed.name then
          return parsed.name
        end
      end
      return nil
    end
  },
  {
    markers = { "Cargo.toml" },
    type = "rust",
    name_from = "Cargo.toml",
    parser = function(path)
      local cargo_file = path .. "/Cargo.toml"
      local file = io.open(cargo_file, "r")
      if file then
        local content = file:read("*all")
        file:close()
        -- Simple TOML parsing for name field
        local name = content:match('name%s*=%s*"([^"]+)"')
        return name
      end
      return nil
    end
  },
  {
    markers = { "go.mod" },
    type = "golang",
    name_from = "go.mod",
    parser = function(path)
      local go_file = path .. "/go.mod"
      local file = io.open(go_file, "r")
      if file then
        local content = file:read("*all")
        file:close()
        -- Extract module name from go.mod
        local name = content:match('module%s+([%w%.%-_/]+)')
        if name then
          -- Get the last part of the module path
          return name:match('([^/]+)$') or name
        end
      end
      return nil
    end
  },
  {
    markers = { "requirements.txt", "setup.py", "pyproject.toml", "poetry.lock" },
    type = "python",
    name_from = "directory",
    parser = function(path)
      -- For Python projects, use directory name
      return path:match('([^/]+)$')
    end
  },
  {
    markers = { "pom.xml" },
    type = "java",
    name_from = "pom.xml",
    parser = function(path)
      local pom_file = path .. "/pom.xml"
      local file = io.open(pom_file, "r")
      if file then
        local content = file:read("*all")
        file:close()
        -- Simple XML parsing for artifactId
        local name = content:match('<artifactId>([^<]+)</artifactId>')
        return name
      end
      return nil
    end
  },
  {
    markers = { "Makefile", "makefile" },
    type = "c_cpp",
    name_from = "directory",
    parser = function(path)
      return path:match('([^/]+)$')
    end
  },
  {
    markers = { ".git" },
    type = "git-project",
    name_from = "directory",
    parser = function(path)
      return path:match('([^/]+)$')
    end
  }
}

-- Common project search paths
local common_project_paths = {
  os.getenv("HOME") .. "/github",
  os.getenv("HOME") .. "/Projects",
  os.getenv("HOME") .. "/Code",
  os.getenv("HOME") .. "/Development",
  os.getenv("HOME") .. "/work",
  os.getenv("HOME") .. "/src",
  os.getenv("HOME") .. "/repos",
  "/usr/local/src",
  "/opt"
}

-- Initialize the projects module
function M.init(user_config)
  config = user_config
end

-- Check if a file or directory exists
local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

-- Check if directory exists
local function dir_exists(path)
  local handle = io.popen("test -d '" .. path .. "' && echo 'exists'")
  if handle then
    local result = handle:read("*all")
    handle:close()
    return result:find("exists") ~= nil
  end
  return false
end

-- Detect project type and information from a path
function M.detect_project(path)
  if not path or not dir_exists(path) then
    return nil
  end

  -- Clean up path
  path = path:gsub("file://", ""):gsub("/$", "")

  for _, pattern in ipairs(project_patterns) do
    for _, marker in ipairs(pattern.markers) do
      local marker_path = path .. "/" .. marker
      if file_exists(marker_path) or dir_exists(marker_path) then
        local project_name = nil

        -- Try to extract name using parser
        if pattern.parser then
          project_name = pattern.parser(path)
        end

        -- Fallback to directory name
        if not project_name then
          project_name = path:match('([^/]+)$')
        end

        -- Clean up project name
        if project_name then
          project_name = project_name:gsub("[^%w%-_]", "-"):lower()
        end

        return {
          name = project_name,
          type = pattern.type,
          path = path,
          marker = marker,
          marker_path = marker_path
        }
      end
    end
  end

  return nil
end

-- Find all projects in common locations
function M.find_all_projects()
  local projects = {}
  local seen_paths = {}

  -- Search in common project directories
  for _, search_path in ipairs(common_project_paths) do
    if dir_exists(search_path) then
      local projects_in_path = M.scan_directory_for_projects(search_path, 2) -- max depth 2
      for _, project in ipairs(projects_in_path) do
        if not seen_paths[project.path] then
          table.insert(projects, project)
          seen_paths[project.path] = true
        end
      end
    end
  end

  return projects
end

-- Scan a directory for projects up to a certain depth
function M.scan_directory_for_projects(directory, max_depth)
  local projects = {}

  if max_depth <= 0 or not dir_exists(directory) then
    return projects
  end

  -- Check if current directory is a project
  local project_info = M.detect_project(directory)
  if project_info then
    table.insert(projects, project_info)
    return projects -- Don't recurse into subdirectories if this is already a project
  end

  -- List subdirectories and scan them
  local handle = io.popen("find '" .. directory .. "' -maxdepth 1 -type d 2>/dev/null")
  if handle then
    for line in handle:lines() do
      if line ~= directory then -- Skip the current directory
        local sub_projects = M.scan_directory_for_projects(line, max_depth - 1)
        for _, sub_project in ipairs(sub_projects) do
          table.insert(projects, sub_project)
        end
      end
    end
    handle:close()
  end

  return projects
end

-- Get project information for current working directory
function M.get_current_project(pane)
  local cwd = pane:get_current_working_dir()
  if cwd then
    return M.detect_project(cwd.file_path)
  end
  return nil
end

-- Check if a path is within a project
function M.is_within_project(path, project_path)
  if not path or not project_path then
    return false
  end

  path = path:gsub("file://", ""):gsub("/$", "")
  project_path = project_path:gsub("file://", ""):gsub("/$", "")

  return path:find(project_path, 1, true) == 1
end

-- Find the project root for a given path
function M.find_project_root(start_path)
  if not start_path then
    return nil
  end

  local current_path = start_path:gsub("file://", ""):gsub("/$", "")

  -- Walk up the directory tree looking for project markers
  while current_path and current_path ~= "/" do
    local project_info = M.detect_project(current_path)
    if project_info then
      return project_info
    end

    -- Move up one directory
    current_path = current_path:match("(.+)/[^/]+$")
  end

  return nil
end

-- Get recently accessed projects (based on workspace states)
function M.get_recent_projects()
  -- This would integrate with the workspace manager to get recent projects
  -- For now, return empty list
  return {}
end

-- Add custom project detection pattern
function M.add_project_pattern(pattern)
  table.insert(project_patterns, pattern)
end

-- Get all supported project types
function M.get_supported_types()
  local types = {}
  for _, pattern in ipairs(project_patterns) do
    types[pattern.type] = true
  end

  local type_list = {}
  for type_name, _ in pairs(types) do
    table.insert(type_list, type_name)
  end

  table.sort(type_list)
  return type_list
end

return M
