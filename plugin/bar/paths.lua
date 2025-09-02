local utilities = require "bar.utilities"

---@private
---@class bar.paths
local M = {}

---Finds the git directory starting from the given directory and moving up the directory tree.
---@param directory string
---@return string|nil
local find_git_dir = function(directory)
  directory = directory:gsub("~", utilities.home)

  while directory do
    local handle = io.open(directory .. "/.git/HEAD", "r")
    if handle then
      handle:close()
      directory = directory:match "([^/]+)$"
      return directory
    elseif directory == "/" or directory == "" then
      break
    else
      directory = directory:match "(.+)/[^/]*"
    end
  end

  return nil
end

---gets the current working directory of the given pane.
---@param pane table
---@param search_git_root_instead boolean
---@return string
M.get_cwd = function(pane, search_git_root_instead)
  local cwd = ""
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    if type(cwd_uri) == "userdata" then
      -- Running on a newer version of wezterm and we have
      -- a URL object here, making this simple!

      ---@diagnostic disable-next-line: undefined-field
      cwd = cwd_uri.file_path
    else
      -- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
      -- which doesn't have the Url object
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find "/"
      if slash then
        -- and extract the cwd from the uri, decoding %-encoding
        cwd = cwd_uri:sub(slash):gsub("%%(%x%x)", function(hex)
          return string.char(tonumber(hex, 16))
        end)
      end
    end

    -- normalize slashes
    cwd = cwd:gsub("\\", "/")
    local home = (utilities.home or ""):gsub("\\", "/")

    -- escape Lua pattern characters in home path
    local function esc(s)
      return (s:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])","%%%1"))
    end
    local home_pat = esc(home)

    -- replace if cwd starts with $HOME
    cwd = cwd:gsub("^" .. home_pat, "~")
    -- also handle paths that come with an extra leading slash (like /C:/Users/Name)
    cwd = cwd:gsub("^/" .. home_pat, "~")


    ---search for the git root of the project if specified
    if search_git_root_instead then
      local git_root = find_git_dir(cwd)
      cwd = git_root or cwd ---fallback to cwd
    end
  end

  return cwd
end

return M
