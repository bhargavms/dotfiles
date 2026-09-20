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

local function home_dir()
  return os.getenv('HOME') or ''
end

local function github_root()
  return config.github_root or (home_dir() .. '/github')
end

local function projects_root()
  return config.projects_dir or (home_dir() .. '/Projects')
end

local function shell_escape(path)
  return path:gsub("'", "'\\''")
end

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
  local handle = io.popen("test -d '" .. shell_escape(path) .. "' && echo 'exists'")
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

local function list_immediate_subdirs(directory)
  local dirs = {}
  if not dir_exists(directory) then
    return dirs
  end

  local handle = io.popen(
    "find '"
      .. shell_escape(directory)
      .. "' -mindepth 1 -maxdepth 1 -type d 2>/dev/null"
  )
  if handle then
    for line in handle:lines() do
      table.insert(dirs, line)
    end
    handle:close()
  end

  table.sort(dirs)
  return dirs
end

local function add_project(projects, seen_paths, project_info)
  if project_info and not seen_paths[project_info.path] then
    seen_paths[project_info.path] = true
    table.insert(projects, project_info)
  end
end

-- ~/github/<owner>/<repo> and ~/Projects/<project>
function M.find_all_projects()
  local projects = {}
  local seen_paths = {}

  local gh = github_root()
  if dir_exists(gh) then
    for _, owner_path in ipairs(list_immediate_subdirs(gh)) do
      local owner = owner_path:match('([^/]+)$')
      for _, repo_path in ipairs(list_immediate_subdirs(owner_path)) do
        local info = M.detect_project(repo_path)
        if info and owner then
          info.github_owner = owner
          info.github_repo = repo_path:match('([^/]+)$')
        end
        add_project(projects, seen_paths, info)
      end
    end
  end

  local pr = projects_root()
  for _, project_path in ipairs(list_immediate_subdirs(pr)) do
    add_project(projects, seen_paths, M.detect_project(project_path))
  end

  table.sort(projects, function(a, b)
    return a.path < b.path
  end)

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
