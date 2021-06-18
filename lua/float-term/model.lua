local api = vim.api
local fn = vim.fn

local M = {}

M.term_list = {}
M.current_term = nil

function M:get_term_index(term)
  for i,t in ipairs(M.term_list) do
    if t == term then
      return i
    end
  end
end

function M:get_set_default()
  if table.getn(term_list) == 0 then
    M.current_term = model:register_terminal(float_terminal_options.default_term_name)
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
    table.remove(M.term_list,index)
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
  if not name then
    local ind = table.getn(M.term_list)
    name = float_terminal_options.auto_tab(ind)
  elseif M:find_terminal_by_name(name) then
    return
  end
  local buf = api.nvim_create_buf(true, true)
  local new_term = { name = name, buffer = buf }
  table.insert(M.term_list, new_term)
  return new_term
end

function M:close_term(term)
  local term_ind = M:get_term_index(term)
  table.remove(M.term_list,term_ind)
  local remaining = table.getn(M.term_list)
  if term == M.current_term and remaining > 0 then
    if term_nd > 1 then 
      M.current_term = M.term_list[term_ind -1]
    else
      M.current_term = M.term_list[term_ind]
    end
    elseif remaining == 0 then
      M:float_close()
    else
      M:render_tab_buffer()
  end
end

function M:find_relative_term(rel_ind)
  local term_len = table.getn(M.termList)
  if term_len == 0 then return nil end
  local current_ind = M:get_term_index(M.current_term)
  local new_ind = (current_ind + rel_ind -1) % term_len + 1
  return M.term_list[new_ind]
end

return M
