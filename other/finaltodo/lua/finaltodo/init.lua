local M = {}

local config = require("finaltodo.config")
local search = require("finaltodo.search")
local ui = require("finaltodo.ui")
local actions = require("finaltodo.actions")
local git = require("finaltodo.git")

local initialized = false

local function setup_commands()
  vim.api.nvim_create_user_command("FinalTodo", function(opts)
    local args = opts.args
    if args == "" then
      ui.open()
    elseif args == "refresh" then
      actions.refresh()
    elseif args == "open" then
      actions.filter_open()
    elseif args == "closed" then
      actions.filter_closed()
    elseif args == "all" then
      actions.show_all()
    elseif args == "new" then
      actions.create_todo()
    elseif args == "push" then
      git.push_to_repo()
    elseif args == "pull" then
      git.sync_from_repo()
    elseif args == "repo" then
      git.create_repo()
    else
      vim.notify("Unknown command: " .. args, vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    complete = function()
      return {
        "refresh",
        "open",
        "closed",
        "all",
        "new",
        "push",
        "pull",
        "repo",
      }
    end,
  })
  
  vim.api.nvim_create_user_command("FinalTodoSearch", function(opts)
    local search_dir = opts.args ~= "" and opts.args or nil
    ui.open(search_dir)
  end, {
    nargs = "?",
    complete = "dir",
  })
end

local function setup_keymaps(opts)
  local keymaps = opts.keymaps or config.defaults.keymaps
  
  vim.keymap.set("n", keymaps.open_dashboard, function()
    ui.open()
  end, { desc = "Open FinalTodo dashboard" })
  
  vim.keymap.set("n", keymaps.new_todo, function()
    actions.create_todo()
  end, { desc = "Create new TODO" })
  
  vim.keymap.set("n", keymaps.refresh, function()
    actions.refresh()
  end, { desc = "Refresh FinalTodo list" })
  
  vim.keymap.set("n", keymaps.filter_open, function()
    actions.filter_open()
  end, { desc = "Filter open todos" })
  
  vim.keymap.set("n", keymaps.filter_closed, function()
    actions.filter_closed()
  end, { desc = "Filter closed todos" })
  
  vim.keymap.set("n", keymaps.show_all, function()
    actions.show_all()
  end, { desc = "Show all todos" })
  
  vim.keymap.set("n", keymaps.toggle, function()
    local state = ui.get_state()
    if state.filtered_results and state.cursor_pos then
      actions.toggle_item(state.filtered_results[state.cursor_pos], function()
        ui.refresh()
      end)
    end
  end, { desc = "Toggle current todo" })
end

local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("FinalTodo", { clear = true })
  
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*",
    callback = function()
      local state = ui.get_state()
      if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        search.invalidate_cache()
      end
    end,
  })
  
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    callback = function()
      vim.defer_fn(function()
        git.setup_repo_on_first_run()
      end, 1000)
    end,
  })
end

local function check_dependencies()
  if not search.check_ripgrep() then
    vim.notify(
      "FinalTodo: ripgrep (rg) is required but not found. Please install it.",
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

function M.setup(opts)
  if initialized then
    return
  end
  
  config.setup(opts)
  
  if not check_dependencies() then
    return
  end
  
  setup_commands()
  setup_keymaps(config.get())
  setup_autocmds()
  
  initialized = true
end

M.open = ui.open
M.close = ui.close
M.refresh = ui.refresh
M.toggle = actions.toggle_item
M.create_todo = actions.create_todo
M.push = git.push_to_repo
M.pull = git.sync_from_repo

return M