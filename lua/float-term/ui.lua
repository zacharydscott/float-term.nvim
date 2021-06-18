api = vim.api
fn = vim.fn
model = require('float-term.model')

local tewm_window
local term_dummy_buf = -1
local save_win = nil
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
  tewm_window = api.nvim_open_win(term_dummy_buf,0,term_opts)
end

function M:close_float_windows()
  if api.nvim_win_is_valid(tewm_window) then
    api.nvim_win_hide(tewm_window)
  end
  if api.nvim_win_is_valid(tab_window) then
    api.nvim_win_hide(tab_window)
  end
  if save_win and api.nvim_win_is_valid(save_win) then
    api.nvim_set_current_win(save_win)
  end
  tewm_window = -1
  tab_window = -1
end

function M:is_term_tab_open()
  return api.nvim_win_is_valid(tewm_window)
end

function M:render_tab_buffer()
  model:clear_invalid_terminals()
  local select_start = 0
  local select_end = 0
  local def_spacing = float_terminal_options.tab_default_marker
  if not def_spacing then
    local select_len = float_terminal_options.tab_default_marker 
    for i=1,select_len do def_spacing = def_spacing..' ' end
  end
  local tab_string = float_terminal_options.tab_title
  for _,v in ipairs(model.term_list) do
    if model.current_term.buffer == v.buffer then
      select_start = fn.len(tab_string)
      select_end = select_start +
        fn.len(float_terminal_options.tab_selected_marker or '') +
        fn.len(v.name or '')
      tab_string = tab_string..float_terminal_options.tab_selected_marker
    else
      tab_string = tab_string..def_spacing
    end
    tab_string = tab_string..v.name..float_terminal_options.tab_separation_marker
  end
  tab_string = string.sub(
    tab_string,
    1,
    string.len(tab_string) -
    string.len(float_terminal_options.tab_separation_marker))
  api.nvim_buf_set_lines(tab_buffer,0,1,false,{tab_string})
  api.nvim_buf_add_highlight(tab_buffer,-1,'FloatTermDefaultTab',0,0,select_start)
  api.nvim_buf_add_highlight(tab_buffer,-1,'FloatTermSelectTab',0,select_start, select_end)
  api.nvim_buf_add_highlight(tab_buffer,-1,'FloatTermDefaultTab',0,select_end,-1)
end

function M:show_terminal(term)
  api.nvim_win_set_buf(tewm_window,term.buffer)
  local buftype = api.nvim_buf_get_option(term.buffer,'buftype')
  if buftype ~= 'terminal' then
    local last_window = api.nvim_get_current_win()
    api.nvim_set_current_win(tewm_window)
    if api.nvim_win_is_valid(tewm_window) then
      api.nvim_win_set_buf(tewm_window,term.buffer)
      fn.termopen(float_terminal_options.term_cmd)
      api.nvim_buf_set_name(term.buffer,term.buffer..'.TERM_BUF')
      api.nvim_win_set_buf(last_window,term.buffer)
    else
      fn.termopen(float_terminal_options.term_cmd)
    end
  end
  if float_terminal_options.auto_enter then
    api.nvim_exec(':normal! a', true)
  end
  M:render_tab_buffer()
end

return M
