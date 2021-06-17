api = vim.api

local M = {}

local term_options = {
  margin = 5,
  default_term_name = 'first',
  term_cmd = 'cmd.exe',
  tab_selected_marker = '🗹 ',
  tab_selected_default_marker = '  ',
  tab_separation_marker = ' | ',
  auto_enter = true,
  tab_title = 'termainals: '
}

-- table with buffer numbers telling if they've been initialized
local terminals = {}
local current_term = nil
local terminal_window = -1
local tab_buffer = -1
local tab_window = -1

function M:term_index(term)
  for i,t in ipairs(terminals) do
    if t == term then
      return i
    end
  end
end

function M:find_terminal_by_name(name)
  if type(name) == number then
    name = tostring(number)
  end
  for _,term in ipairs(terminals) do
    if term.name == name then
      return term
    end
  end
  return false
end

function M:float_toggle()
  if not M:is_term_tab_open() then
    M:float_open()
  else
    M:float_close()
  end
end

function M:float_close()
  if api.nvim_win_is_valid(terminal_window) then
    api.nvim_win_hide(terminal_window)
  end
  if api.nvim_win_is_valid(tab_window) then
    api.nvim_win_hide(tab_window)
  end
  terminal_window = -1
  tab_window = -1
end

function M:float_open()
  -- initialize window parameters
  local width = api.nvim_get_option('columns')
  local height = 40
  local term_opts = {
    relative = 'editor',
    width = width - 2*term_options.margin,
    height = height - 2*term_options.margin,
    col = term_options.margin,
    row = term_options.margin + 1,
    border= {'','','','│','┘','─','└','│'},
    style = 'minimal'
  }
  local tab_opts = {
    relative = 'editor',
    width = width - 2*term_options.margin,
    height = 1,
    col = term_options.margin,
    row = term_options.margin - 1,
    -- boarder = 'single',
    border= {'┌','─','┐','│','','','','│'},
    style = 'minimal'
  }

  -- show terminal tab
  if not api.nvim_buf_is_valid(tab_buffer) then
    tab_buffer = api.nvim_create_buf(true, true)
  end
  tab_window = api.nvim_open_win(tab_buffer,0,tab_opts)
  M:render_tab_buffer()

  -- show terminal
  M:clear_invalid_terminals()
  if table.getn(terminals) == 0 then
    current_term = M:register_terminal(term_options.default_term_name)
  end
  if not current_term then current_term = terminals[1] end
  terminal_window = api.nvim_open_win(current_term.buffer,0,term_opts)
  M:show_terminal(current_term)


  api.nvim_set_current_win(terminal_window)
end

function M:register_terminal(name)
  if not name then 
    local ind = table.getn(terminals)
    while M:find_terminal_by_name(ind) do
      ind = ind + 1
    end
    name = tostring(ind)
  elseif M:find_terminal_by_name(name) then
    return
  end
  local buf = api.nvim_create_buf(true, true)
  local new_term = { name = name, buffer = buf }
  table.insert(terminals, new_term)
  return new_term
end

function M:switch_terminal(name)
  local term = M:find_terminal_by_name(name)
  if not term then
    return
  end
  M:show_terminal(term)
end

function M:add_terminal(name)
  local new_term = M:register_terminal(name)
  if not new_term then
    return
  end
  M:show_terminal(new_term)
end

function M:is_term_tab_open()
  return api.nvim_win_is_valid(terminal_window)
end

function M:show_terminal(term)
  print(term)
  current_term = term
  api.nvim_win_set_buf(terminal_window,term.buffer)
  local buftype = api.nvim_buf_get_option(term.buffer,'buftype')
  if buftype ~= 'terminal' then
    local last_window = api.nvim_get_current_win()
    api.nvim_set_current_win(terminal_window)
    if api.nvim_win_is_valid(terminal_window) then
      api.nvim_win_set_buf(terminal_window,term.buffer)
      vim.fn.termopen(term_options.term_cmd)
      if term_options.auto_enter then
        api.nvim_exec(':normal! a', true)
      end
      api.nvim_buf_set_name(term.buffer,'TERM_BUF'..term.buffer)
      api.nvim_win_set_buf(last_window,term.buffer)
    else
      vim.fn.termopen(term_options.term_cmd)
    end
  end
  M:render_tab_buffer()
end

function M:clear_invalid_terminals()
  local index = M:term_index(current_term)
      print('clearing', index)
  current_term = nil
  for i,v in ipairs(terminals) do
    print(i,v, table.getn(terminals))
  end
  while not current_term and table.getn(terminals) > 0 do
    local new_term = terminals[index]
    if api.nvim_buf_is_valid(new_term.buffer) then
      print('after clear',new_term.name)
      current_term = new_term
      break
    end
    table.remove(terminals,index)
    if index > 1 then
      index = index - 1
    end
  end
  for i,v in ipairs(terminals) do
    local buf = v.buffer
    if  buf ~= -1 then
      if not api.nvim_buf_is_valid(buf) then
        table.remove(terminals,i)
      end
    end
  end
end

function M:render_tab_buffer()
  M:clear_invalid_terminals()
  local def_spacing = term_options.tab_selected_default_marker
  if not def_spacing then
    local select_len = term_options.tab_selected_default_marker 
    for i=1,select_len do def_spacing = def_spacing..' ' end
  end
  local tab_string = term_options.tab_title
  for _,v in ipairs(terminals) do
    if current_term.buffer == v.buffer then
      tab_string = tab_string..term_options.tab_selected_marker
    else
      tab_string = tab_string..def_spacing
    end
    tab_string = tab_string..v.name..term_options.tab_separation_marker
  end
  tab_string = string.sub(tab_string, 1, string.len(tab_string) - string.len(term_options.tab_separation_marker))
  api.nvim_buf_set_lines(tab_buffer,0,1,false,{tab_string})
end

function M:handle_term_close()
  api.nvim_exec('echoerr "rsasr"',true)
  M:clear_invalid_terminals()
  local term_len = table.getn(terminals)
  if term_len == 0 then M:float_close() return
  end
  M:float_open()
  if M:is_term_tab_open() then
    M:show_terminal(current_term)
    M:render_tab_buffer()
  end
end

function M:cycle_term(relative_index)
  term_len = table.getn(terminals)
  if term_len == 0 then return end
  current_ind = M:term_index(current_term)
  new_term = terminals[(current_ind + relative_index - 1) % term_len + 1]
  print(new_term, current_term)
  M:show_terminal(new_term)
end

api.nvim_exec([[
augroup FLOAT_TERMINAL
  au! WinClosed TERM_BUF* lua tf:handle_term_close()
augroup END
]],true)

tf = M
return M

