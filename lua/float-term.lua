local api = vim.api
local fn = vim.fn
model = require('float-term.model')
ui = require('float-term.ui')
local M = {}

api.nvim_exec([[hi link FloatTermDefaultTab Normal |hi link FloatTermSelectTab Cursor]],true)
local float_terminal_options = {
  margin = 5,
  default_term_name = 'first',
  term_cmd = 'cmd.exe',
  tab_selected_marker = '',
  tab_default_marker = '',
  tab_separation_marker = ' | ',
  auto_enter = true,
  auto_tab = require('nvim-term-float.auto-tab'):roman_numerals(),
  tab_title = 'termainals: '
}

local save_win

function M:setup(config)
  for n,v in pairs(config) do
    float_terminal_options[n] = v or float_terminal_options[n]
  end

  -- try to keep the default space and marker the same if none is rovided
  if confg.tab_selected_marker and not confg.tab_default_marker then
    local def_marker = ''
    local len = string.len(config.tab_selected_marker)
    while len > 0 do
      def_marker = def_marker..' '
    end
  end
end

function M:float_toggle()
  if not M:is_term_tab_open() then
    M:float_open()
  else
    M:float_close()
  end
end


function M:float_open()
  save_win = api.nvim_get_current_win()
  -- initialize window parameters
  local width = api.nvim_get_option('columns')
  local height = 40
  local term_opts = {
    relative = 'editor',
    width = width - 2*float_terminal_options.margin,
    height = height - 2*float_terminal_options.margin,
    col = float_terminal_options.margin,
    row = float_terminal_options.margin + 1,
    border = {'','','','│','┘','─','└','│'},
    style = 'minimal'
  }
  local tab_opts = {
    relative = 'editor',
    width = width - 2*float_terminal_options.margin,
    height = 1,
    col = float_terminal_options.margin,
    row = float_terminal_options.margin - 1,
    -- boarder = 'single',
    border= {'┌','─','┐','│','','','','│'},
    style = 'minimal'
  }
  ui:open_float_windows(tab_opts,term_opts)
  term = model.get_set_default()
  ui:show_terminal(term)
end

function M:switch_terminal(name)
  local term = model:find_terminal_by_name(name)
  if not term then
    return
  end
  ui:show_terminal(term)
end

function M:add_terminal(name)
  local new_term = M:register_terminal(name)
  if not new_term then
    return
  end
  ui:show_terminal(new_term)
end

function M:close_term_by_name(name)
  local term = model:find_terminal_by_name(name)
  if term then
    M:close_term(term)
  else 
    print('No terminal "'..name..'" exists.')
  end
end

function M:cycle_term(rel_ind)
  local new_term = model:find_terminal_by_name(rel_ind)
  if new_term then
    model.current_term = new_term
    ui:show_terminal(new_term)
  end
end


return M
