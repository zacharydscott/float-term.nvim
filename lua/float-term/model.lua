local api = vim.api
local fn = vim.fn

local M = {}

M.term_list = {}
M.current_term = nil
M.tab_options = {
    title = 'Float Terms: ',
    selected_marker = '',
    default_marker = '',
    separation_marker = ' | ',
    auto_tab = require('float-term.auto-tab-fn'):roman_numerals(),
}

function M:get_term_index(term)
  for i,t in ipairs(M.term_list) do
    if t == term then
      return i
    end
  end
end

function M:get_set_default(default_name)
  if table.getn(M.term_list) == 0 then
    M.current_term = M:register_terminal(default_name)
  end
  return M.current_term
end

function M:find_terminal_by_name(name)
  if type(name) == number then
    name = tostring(number)
  end
  for _,term in ipairs(M.term_list) do
    if term.name == name then
      return term
    end
  end
  return nil
end

function M:clear_invalid_term_list()
  local index = M:get_term_index(M.current_term)
  M.current_term = nil
  while not M.current_term and table.getn(M.term_list) > 0 do
    local new_term = M.term_list[index]
    if api.nvim_buf_is_valid(new_term.buffer) then
      M.current_term = new_term
      break
    end
    local term = table.remove(M.term_list,index)
    if index > 1 then
      index = index - 1
    end
  end
  for i,v in ipairs(M.term_list) do
    local buf = v.buffer
    if  buf ~= -1 then
      if not api.nvim_buf_is_valid(buf) then
        table.remove(M.term_list,i)
      end
    end
  end
end

function M:register_terminal(name)
  if M:find_terminal_by_name(name) then
    print('Terminal "'..name..'" has already been added')
    return nil
  end
  local buf = api.nvim_create_buf(true, true)
  local new_term = { name = name, buffer = buf }
  table.insert(M.term_list, new_term)
  return new_term
end

function M:remove_term(term)
  local term_ind = M:get_term_index(term)
  local term = table.remove(M.term_list,term_ind)
  api.nvim_buf_delete(term.buffer, {})
  local remaining = table.getn(M.term_list)
  if term == M.current_term and remaining > 0 then
    if term_ind > 1 then
      M.current_term = M.term_list[term_ind -1]
    else
      M.current_term = M.term_list[term_ind]
    end
  end
end

function M:find_relative_term(rel_ind)
  local term_len = table.getn(M.term_list)
  if term_len == 0 then return nil end
  local current_ind = M:get_term_index(M.current_term)
  local new_ind = (current_ind + rel_ind -1) % term_len + 1
  return M.term_list[new_ind]
end

return M
