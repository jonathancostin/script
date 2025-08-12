local M = {}
local config = require("finaltodo.config")

function M.jump_to_item(item)
  if not item then
    return
  end
  
  local ui = require("finaltodo.ui")
  ui.close()
  
  local file_path = vim.fn.fnamemodify(item.file, ":p")
  
  vim.cmd("edit " .. vim.fn.fnameescape(file_path))
  
  vim.api.nvim_win_set_cursor(0, { item.line, 0 })
  
  vim.cmd("normal! zz")
end

function M.toggle_item(item, callback)
  if not item then
    return
  end
  
  local file_path = vim.fn.fnamemodify(item.file, ":p")
  
  local file = io.open(file_path, "r")
  if not file then
    vim.notify("Cannot open file: " .. file_path, vim.log.levels.ERROR)
    return
  end
  
  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()
  
  if item.line > #lines then
    vim.notify("Line number out of bounds", vim.log.levels.ERROR)
    return
  end
  
  local original_line = lines[item.line]
  local modified_line = original_line
  
  if original_line:match("%[[ ]%]") then
    modified_line = original_line:gsub("%[[ ]%]", "[x]")
  elseif original_line:match("%[x%]") or original_line:match("%[X%]") then
    modified_line = original_line:gsub("%[[xX]%]", "[ ]")
  else
    local patterns = {
      { "TODO", "DONE" },
      { "FIXME", "FIXED" },
    }
    
    for _, pattern_pair in ipairs(patterns) do
      if original_line:match(pattern_pair[1]) then
        modified_line = original_line:gsub(pattern_pair[1], pattern_pair[2])
        break
      elseif original_line:match(pattern_pair[2]) then
        modified_line = original_line:gsub(pattern_pair[2], pattern_pair[1])
        break
      end
    end
  end
  
  if original_line == modified_line then
    vim.notify("Could not toggle item", vim.log.levels.WARN)
    return
  end
  
  lines[item.line] = modified_line
  
  file = io.open(file_path, "w")
  if not file then
    vim.notify("Cannot write to file: " .. file_path, vim.log.levels.ERROR)
    return
  end
  
  for _, line in ipairs(lines) do
    file:write(line .. "\n")
  end
  file:close()
  
  local bufnr = vim.fn.bufnr(file_path)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    vim.api.nvim_buf_set_lines(bufnr, item.line - 1, item.line, false, { modified_line })
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent write")
    end)
  end
  
  vim.notify("Toggled: " .. item.file .. ":" .. item.line, vim.log.levels.INFO)
  
  if callback then
    callback()
  end
end

function M.create_todo()
  local cfg = config.get()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  local col = cursor[2]
  
  local todo_text = "TODO: "
  
  local current_line = vim.api.nvim_get_current_line()
  local indent = current_line:match("^%s*") or ""
  
  local comment_string = vim.bo.commentstring
  if comment_string and comment_string ~= "" then
    comment_string = comment_string:gsub("%%s", "")
    todo_text = indent .. comment_string .. " " .. todo_text
  else
    todo_text = indent .. todo_text
  end
  
  vim.api.nvim_buf_set_lines(0, line, line, false, { todo_text })
  
  vim.api.nvim_win_set_cursor(0, { line + 1, #todo_text })
  
  vim.cmd("startinsert!")
end

function M.filter_open()
  local ui = require("finaltodo.ui")
  ui.set_filter("open")
end

function M.filter_closed()
  local ui = require("finaltodo.ui")
  ui.set_filter("closed")
end

function M.show_all()
  local ui = require("finaltodo.ui")
  ui.set_filter("all")
end

function M.refresh()
  local ui = require("finaltodo.ui")
  ui.refresh()
end

return M