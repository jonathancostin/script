local M = {}
local config = require("finaltodo.config")

local cache = {
  results = nil,
  timestamp = 0,
}

function M.check_ripgrep()
  local handle = io.popen("which rg 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
  end
  return false
end

local function build_ripgrep_command(search_dir, patterns, ignore_dirs)
  local cmd = { "rg", "--json", "--line-number", "--with-filename", "--no-heading" }
  
  for _, dir in ipairs(ignore_dirs) do
    table.insert(cmd, "--glob")
    table.insert(cmd, "!" .. dir)
  end
  
  table.insert(cmd, "--glob")
  table.insert(cmd, "!.git")
  
  local pattern_regex = "(" .. table.concat(patterns, "|") .. ")"
  table.insert(cmd, pattern_regex)
  table.insert(cmd, search_dir)
  
  return cmd
end

local function parse_ripgrep_output(data)
  local results = {}
  
  for line in data:gmatch("[^\n]+") do
    local ok, json = pcall(vim.json.decode, line)
    if ok and json.type == "match" then
      local match_data = json.data
      table.insert(results, {
        file = match_data.path.text,
        line = match_data.line_number,
        text = match_data.lines.text:gsub("^%s+", ""):gsub("%s+$", ""),
        pattern = match_data.submatches[1] and match_data.submatches[1].match.text or "",
      })
    end
  end
  
  return results
end

local function determine_status(text)
  if text:match("%[x%]") or text:match("%[X%]") then
    return "closed"
  elseif text:match("%[ %]") then
    return "open"
  else
    return "open"
  end
end

function M.search(search_dir, opts)
  opts = opts or {}
  local cfg = config.get()
  
  search_dir = search_dir or vim.fn.getcwd()
  
  if cfg.cache.enabled and cache.results and (vim.loop.now() - cache.timestamp) < cfg.cache.ttl then
    return cache.results
  end
  
  local patterns = opts.patterns or cfg.patterns
  local ignore_dirs = opts.ignore_dirs or cfg.ignore_dirs
  
  local cmd = build_ripgrep_command(search_dir, patterns, ignore_dirs)
  local cmd_str = table.concat(cmd, " ")
  
  local handle = io.popen(cmd_str .. " 2>/dev/null")
  if not handle then
    return {}
  end
  
  local output = handle:read("*a")
  handle:close()
  
  local results = parse_ripgrep_output(output)
  
  for _, result in ipairs(results) do
    result.status = determine_status(result.text)
    result.file = vim.fn.fnamemodify(result.file, ":.")
  end
  
  if cfg.cache.enabled then
    cache.results = results
    cache.timestamp = vim.loop.now()
  end
  
  return results
end

function M.search_async(search_dir, opts, callback)
  opts = opts or {}
  local cfg = config.get()
  
  search_dir = search_dir or vim.fn.getcwd()
  
  if cfg.cache.enabled and cache.results and (vim.loop.now() - cache.timestamp) < cfg.cache.ttl then
    callback(cache.results)
    return
  end
  
  local patterns = opts.patterns or cfg.patterns
  local ignore_dirs = opts.ignore_dirs or cfg.ignore_dirs
  
  local cmd = build_ripgrep_command(search_dir, patterns, ignore_dirs)
  
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local output = ""
  
  local handle
  handle = vim.loop.spawn(
    cmd[1],
    {
      args = vim.list_slice(cmd, 2),
      stdio = { nil, stdout, stderr },
    },
    function(code, signal)
      stdout:close()
      stderr:close()
      handle:close()
      
      vim.schedule(function()
        if code == 0 then
          local results = parse_ripgrep_output(output)
          
          for _, result in ipairs(results) do
            result.status = determine_status(result.text)
            result.file = vim.fn.fnamemodify(result.file, ":.")
          end
          
          if cfg.cache.enabled then
            cache.results = results
            cache.timestamp = vim.loop.now()
          end
          
          callback(results)
        else
          callback({})
        end
      end)
    end
  )
  
  vim.loop.read_start(stdout, function(err, data)
    if data then
      output = output .. data
    end
  end)
  
  vim.loop.read_start(stderr, function(err, data)
  end)
end

function M.invalidate_cache()
  cache.results = nil
  cache.timestamp = 0
end

return M