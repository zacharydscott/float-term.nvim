api = vim.api
fn = vim.fn
model = require('float-term.model')

local term_window = -1
local term_dummy_buf = -1
local tab_buffer = -1
local tab_window = -1

local M = {}

function M:open_float_windows(
  tab_opts,
  term_opts
  )
  -- show terminal tab
  if not api.nvim_buf_is_valid(tab_buffer) then
    tab_buffer = api.nvim_create_buf(true, true)
  end
    tab_window = api.nvim_open_win(tab_buffer,0,tab_opts)
    api.nvim_buf_set_name(tab_buffer,tab_buffer..'.TERM_BUF')

  -- show terminal
  if not api.nvim_buf_is_valid(term_dummy_buf) then
    term_dummy_buf = api.nvim_create_buf(true, true)
  end
  term_window = api.nvim_open_win(term_dummy_buf,0,term_opts)
end

function M:close_float_windows()
  if api.nvim_win_is_valid(term_window) then
    api.nvim_win_hide(term_window)
  end
  if api.nvim_win_is_valid(tab_window) then
    api.nvim_win_hide(tab_window)
  end
  if save_win and api.nvim_win_is_valid(save_win) then
    api.nvim_set_current_win(save_win)
  end
  term_window = -1
  tab_window = -1
end

function M:is_term_tab_open()
  return api.nvim_win_is_valid(term_window) and api.nvim_win_is_valid(tab_window)
end

function M:render_tab_buffer()
  model:clear_invalid_term_list()
  local to = model.tab_options
  local select_start = 0
  local select_end = 0
  local def_spacing = to.default_marker
  local tab_string = to.title
  for i,v in ipairs(model.term_list) do
    if model.current_term.buffer == v.buffer then
      select_start = fn.len(tab_string)
      select_end = select_start +
        fn.len(to.selected_marker) +
        fn.len(v.name or '')
      tab_string = tab_string..to.selected_marker
    else
      tab_string = tab_string..def_spacing
    end
    tab_string = tab_string..(v.name or '')..to.separation_marker
  end
  tab_string = string.sub(
    tab_string,
    1,
    string.len(tab_string or '') -
    string.len(to.separation_marker or ''))
  -- add extra spaces for highlighting
  local space_len = api.nvim_get_option('columns') - string.len(tab_string)
  for i=1,space_len do
    tab_string = tab_string..' '
  end
  api.nvim_buf_set_lines(tab_buffer,0,1,false,{tab_string})
  api.nvim_buf_add_highlight(tab_buffer,-1,'FloatTermDefaultTab',0,0,select_start)
  api.nvim_buf_add_highlight(tab_buffer,-1,'FloatTermSelectTab',0,select_start, select_end)
  api.nvim_buf_add_highlight(tab_buffer,-1,'FloatTermDefaultTab',0,select_end,-1)
end

function M:show_terminal(term,cmd,enter)
  api.nvim_win_set_buf(term_window,term.buffer)
  local buftype = api.nvim_buf_get_option(term.buffer,'buftype')
  if buftype ~= 'terminal' then
    local last_window = api.nvim_get_current_win()
    api.nvim_set_current_win(term_window)
    if api.nvim_win_is_valid(term_window) then
      api.nvim_win_set_buf(term_window,term.buffer)
      api.nvim_exec([[au BufUnload <buffer> lua require('float-term'):handle_term_close()]],true)
      fn.termopen(cmd)
      api.nvim_buf_set_name(term.buffer,term.buffer..'.TERM_BUF')
      api.nvim_win_set_buf(last_window,term.buffer)
    else
      fn.termopen(cmd)
    end
  end
  if enter then
    api.nvim_exec(':normal! a', true)
  end
  M:render_tab_buffer()
end

return M
