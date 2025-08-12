local M = {}
local config = require("finaltodo.config")

local function check_gh_cli()
  local handle = io.popen("which gh 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
  end
  return false
end

local function is_git_repo()
  local handle = io.popen("git rev-parse --is-inside-work-tree 2>/dev/null")
  if handle then
    local result = handle:read("*a"):gsub("%s+", "")
    handle:close()
    return result == "true"
  end
  return false
end

local function get_repo_name()
  local cfg = config.get()
  if cfg.github.repo_name then
    return cfg.github.repo_name
  end
  
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ":t")
  return "finaltodo-" .. project_name
end

function M.create_repo(callback)
  if not check_gh_cli() then
    vim.notify("GitHub CLI (gh) is not installed", vim.log.levels.ERROR)
    return
  end
  
  if not is_git_repo() then
    vim.notify("Current directory is not a git repository", vim.log.levels.ERROR)
    return
  end
  
  local cfg = config.get()
  local repo_name = get_repo_name()
  local visibility = cfg.github.private and "--private" or "--public"
  
  vim.ui.input({
    prompt = "Create GitHub repository '" .. repo_name .. "'? (y/n): ",
  }, function(input)
    if input and input:lower() == "y" then
      local cmd = string.format(
        "gh repo create %s %s --source=. --remote=finaltodo 2>&1",
        repo_name,
        visibility
      )
      
      local handle = io.popen(cmd)
      if handle then
        local result = handle:read("*a")
        handle:close()
        
        if result:match("Created repository") or result:match("already exists") then
          vim.notify("GitHub repository created/connected: " .. repo_name, vim.log.levels.INFO)
          
          if callback then
            callback(true, repo_name)
          end
        else
          vim.notify("Failed to create repository: " .. result, vim.log.levels.ERROR)
          if callback then
            callback(false, nil)
          end
        end
      end
    else
      vim.notify("Repository creation cancelled", vim.log.levels.INFO)
      if callback then
        callback(false, nil)
      end
    end
  end)
end

function M.push_to_repo()
  if not check_gh_cli() then
    vim.notify("GitHub CLI (gh) is not installed", vim.log.levels.ERROR)
    return
  end
  
  if not is_git_repo() then
    vim.notify("Current directory is not a git repository", vim.log.levels.ERROR)
    return
  end
  
  vim.ui.select({ "Yes", "No" }, {
    prompt = "Push changes to GitHub?",
  }, function(choice)
    if choice == "Yes" then
      vim.notify("Pushing to GitHub...", vim.log.levels.INFO)
      
      local commands = {
        "git add -A",
        "git commit -m 'Update finaltodo tasks'",
        "git push finaltodo main",
      }
      
      for _, cmd in ipairs(commands) do
        local handle = io.popen(cmd .. " 2>&1")
        if handle then
          local result = handle:read("*a")
          handle:close()
          
          if cmd:match("commit") and result:match("nothing to commit") then
            vim.notify("No changes to commit", vim.log.levels.INFO)
            break
          elseif cmd:match("push") then
            if result:match("Everything up%-to%-date") or result:match("To ") then
              vim.notify("Successfully pushed to GitHub", vim.log.levels.INFO)
            else
              vim.notify("Push failed: " .. result, vim.log.levels.ERROR)
            end
          end
        end
      end
    else
      vim.notify("Push cancelled", vim.log.levels.INFO)
    end
  end)
end

function M.sync_from_repo()
  if not check_gh_cli() then
    vim.notify("GitHub CLI (gh) is not installed", vim.log.levels.ERROR)
    return
  end
  
  if not is_git_repo() then
    vim.notify("Current directory is not a git repository", vim.log.levels.ERROR)
    return
  end
  
  vim.ui.select({ "Yes", "No" }, {
    prompt = "Pull changes from GitHub?",
  }, function(choice)
    if choice == "Yes" then
      vim.notify("Pulling from GitHub...", vim.log.levels.INFO)
      
      local cmd = "git pull finaltodo main 2>&1"
      local handle = io.popen(cmd)
      if handle then
        local result = handle:read("*a")
        handle:close()
        
        if result:match("Already up to date") then
          vim.notify("Already up to date", vim.log.levels.INFO)
        elseif result:match("Fast%-forward") or result:match("Merge made") then
          vim.notify("Successfully pulled from GitHub", vim.log.levels.INFO)
          
          local ui = require("finaltodo.ui")
          ui.refresh()
        else
          vim.notify("Pull failed: " .. result, vim.log.levels.ERROR)
        end
      end
    else
      vim.notify("Pull cancelled", vim.log.levels.INFO)
    end
  end)
end

function M.setup_repo_on_first_run()
  local cfg = config.get()
  if not cfg.github.auto_create_repo then
    return
  end
  
  local data_path = vim.fn.stdpath("data") .. "/finaltodo"
  local marker_file = data_path .. "/.github_setup"
  
  vim.fn.mkdir(data_path, "p")
  
  local file = io.open(marker_file, "r")
  if file then
    file:close()
    return
  end
  
  M.create_repo(function(success, repo_name)
    if success then
      local file = io.open(marker_file, "w")
      if file then
        file:write(repo_name)
        file:close()
      end
    end
  end)
end

return M