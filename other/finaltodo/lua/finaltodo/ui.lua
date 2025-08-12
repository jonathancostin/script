local M = {}
local config = require("finaltodo.config")
local search = require("finaltodo.search")

local state = {
  buf = nil,
  win = nil,
  tab = nil,
  results = {},
  filtered_results = {},
  filter = "all",
  cursor_pos = 1,
}

local function create_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "finaltodo")
  vim.api.nvim_buf_set_name(buf, "FinalTodo")
  return buf
end

local function format_line(item, index)
  local cfg = config.get()
  local icon = item.status == "closed" and cfg.ui.icons.closed or cfg.ui.icons.open
  
  local pattern_icon = ""
  local lower_pattern = item.pattern:lower()
  if lower_pattern:match("todo") then
    pattern_icon = cfg.ui.icons.todo .. " "
  elseif lower_pattern:match("fixme") then
    pattern_icon = cfg.ui.icons.fixme .. " "
  elseif lower_pattern:match("hack") then
    pattern_icon = cfg.ui.icons.hack .. " "
  elseif lower_pattern:match("note") then
    pattern_icon = cfg.ui.icons.note .. " "
  elseif lower_pattern:match("perf") then
    pattern_icon = cfg.ui.icons.perf .. " "
  elseif lower_pattern:match("warning") then
    pattern_icon = cfg.ui.icons.warning .. " "
  end
  
  return string.format(
    "%s %s%s:%d: %s",
    icon,
    pattern_icon,
    item.file,
    item.line,
    item.text
  )
end

local function apply_filter(results, filter)
  if filter == "all" then
    return results
  elseif filter == "open" then
    return vim.tbl_filter(function(item)
      return item.status == "open"
    end, results)
  elseif filter == "closed" then
    return vim.tbl_filter(function(item)
      return item.status == "closed"
    end, results)
  end
  return results
end

local function render_dashboard()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  
  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  
  local lines = {}
  local header = {
    "╔════════════════════════════════════════════════════════════════════╗",
    "║                           FinalTodo                                ║",
    "║                                                                    ║",
    "║  Filter: " .. string.upper(state.filter) .. string.rep(" ", 58 - #state.filter) .. "║",
    "║  Items: " .. #state.filtered_results .. " / " .. #state.results .. string.rep(" ", 59 - #tostring(#state.filtered_results) - #tostring(#state.results)) .. "║",
    "╚════════════════════════════════════════════════════════════════════╝",
    "",
  }
  
  for _, line in ipairs(header) do
    table.insert(lines, line)
  end
  
  if #state.filtered_results == 0 then
    table.insert(lines, "  No items found")
  else
    for i, item in ipairs(state.filtered_results) do
      table.insert(lines, format_line(item, i))
    end
  end
  
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
  
  if state.cursor_pos > #state.filtered_results then
    state.cursor_pos = math.max(1, #state.filtered_results)
  end
  
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local cursor_line = state.cursor_pos + 7
    vim.api.nvim_win_set_cursor(state.win, { cursor_line, 0 })
  end
end

local function setup_keymaps()
  local buf = state.buf
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set("n", "j", function()
    if state.cursor_pos < #state.filtered_results then
      state.cursor_pos = state.cursor_pos + 1
      local cursor_line = state.cursor_pos + 7
      vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
    end
  end, opts)
  
  vim.keymap.set("n", "k", function()
    if state.cursor_pos > 1 then
      state.cursor_pos = state.cursor_pos - 1
      local cursor_line = state.cursor_pos + 7
      vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
    end
  end, opts)
  
  vim.keymap.set("n", "<CR>", function()
    local actions = require("finaltodo.actions")
    actions.jump_to_item(state.filtered_results[state.cursor_pos])
  end, opts)
  
  vim.keymap.set("n", "x", function()
    local actions = require("finaltodo.actions")
    actions.toggle_item(state.filtered_results[state.cursor_pos], function()
      M.refresh()
    end)
  end, opts)
  
  vim.keymap.set("n", "r", function()
    M.refresh()
  end, opts)
  
  vim.keymap.set("n", "o", function()
    M.set_filter("open")
  end, opts)
  
  vim.keymap.set("n", "c", function()
    M.set_filter("closed")
  end, opts)
  
  vim.keymap.set("n", "a", function()
    M.set_filter("all")
  end, opts)
  
  vim.keymap.set("n", "q", function()
    M.close()
  end, opts)
  
  vim.keymap.set("n", "?", function()
    local help = {
      "Keybindings:",
      "  j/k     - Navigate up/down",
      "  <CR>    - Jump to item",
      "  x       - Toggle checkbox",
      "  r       - Refresh list",
      "  o       - Show open items only",
      "  c       - Show closed items only",
      "  a       - Show all items",
      "  q       - Close dashboard",
      "  ?       - Show this help",
    }
    vim.notify(table.concat(help, "\n"), vim.log.levels.INFO, { title = "FinalTodo Help" })
  end, opts)
end

function M.open(search_dir)
  if state.tab and vim.api.nvim_tabpage_is_valid(state.tab) then
    vim.api.nvim_set_current_tabpage(state.tab)
    return
  end
  
  vim.cmd("tabnew")
  state.tab = vim.api.nvim_get_current_tabpage()
  
  state.buf = create_buffer()
  state.win = vim.api.nvim_get_current_win()
  
  vim.api.nvim_win_set_buf(state.win, state.buf)
  
  local cfg = config.get()
  vim.api.nvim_win_set_option(state.win, "number", false)
  vim.api.nvim_win_set_option(state.win, "relativenumber", cfg.ui.relative_numbers)
  vim.api.nvim_win_set_option(state.win, "wrap", cfg.ui.wrap)
  vim.api.nvim_win_set_option(state.win, "cursorline", true)
  vim.api.nvim_win_set_option(state.win, "signcolumn", "no")
  
  setup_keymaps()
  
  search.search_async(search_dir, {}, function(results)
    state.results = results
    state.filtered_results = apply_filter(results, state.filter)
    state.cursor_pos = 1
    render_dashboard()
  end)
end

function M.close()
  if state.tab and vim.api.nvim_tabpage_is_valid(state.tab) then
    vim.cmd("tabclose")
  end
  state.tab = nil
  state.win = nil
  state.buf = nil
end

function M.refresh()
  search.invalidate_cache()
  search.search_async(nil, {}, function(results)
    state.results = results
    state.filtered_results = apply_filter(results, state.filter)
    render_dashboard()
  end)
end

function M.set_filter(filter)
  state.filter = filter
  state.filtered_results = apply_filter(state.results, filter)
  state.cursor_pos = 1
  render_dashboard()
end

function M.get_state()
  return state
end

return M