local api = vim.api
local fn = vim.fn
model = require('float-term.model')
ui = require('float-term.ui')
local M = {}

api.nvim_exec([[hi link FloatTermDefaultTab Normal |hi link FloatTermSelectTab Cursor]],true)
local float_terminal_options = {
  margin = 5,
  term_cmd = 'cmd.exe',
  tab = {
    title = 'Float Terms: ',
    selected_marker = '',
    default_marker = '',
    separation_marker = ' | ',
    auto_tab = require('float-term.auto-tab-fn'):roman_numerals(),
  },
  auto_enter = true,
}

local save_win

function M:setup(config)
  for n,v in pairs(config) do
    float_terminal_options[n] = v or float_terminal_options[n]
  end
  local tab = float_terminal_options.tab
  -- try to keep the default space and marker the same if none is rovided
  if config.tab and confg.tab.selected_marker and not confg.tab.default_marker then
    local def_marker = ''
    local len = string.len(config.tab.selected_marker)
    while len > 0 do
      def_marker = def_marker..' '
      len = len - 1
    end
    tab.default_marker = def_marker
  end
  tab.default_marker = tab.default_marker or ''
  tab.selected_marker = tab.selected_marker or ''
  tab.title = tab.title or ''
  model.tab_options = float_terminal_options.tab
end

function M:float_toggle()
  if not ui:is_term_tab_open() then
    M:float_open()
  else
    M:float_close()
  end
end

function M:float_close()
  ui:close_float_windows()
  if api.nvim_win_is_valid(save_win) then
    api.nvim_set_current_win(save_win)
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
  local def_term_name = float_terminal_options.default_term_name or
  float_terminal_options.tab.auto_tab(1)
  print('def_term',def_term_name)
  term = model:get_set_default(def_term_name)
  ui:show_terminal(term, float_terminal_options.term_cmd, float_terminal_options.auto_enter)
end

function M:switch_terminal(name)
  local term = model:find_terminal_by_name(name)
  if not term then
    return
  end
  ui:show_terminal(term, float_terminal_options.term_cmd, float_terminal_options.auto_enter)
end

function M:add_terminal(name)
  if not name then
    local len = table.getn(model.term_list)
    name = float_terminal_options.tab.auto_tab(len + 1)
  end
  local new_term = model:register_terminal(name)
  print('tttttt')
  print(new_term and new_term.name)
  if not new_term then
    return
  end
  model.current_term = new_term
  ui:show_terminal(new_term,float_terminal_options.term_cmd, float_terminal_options.auto_enter)
end

local function close_term_base(term)
  model:remove_term(term)
  if ui.is_term_tab_open() then
    if table.getn(model.term_list) > 0 then
      ui.show_terminal(model.current_term, float_terminal_options.term_cmd, float_terminal_options.auto_enter)
      ui.render_tab_buffer()
    else
      M:float_close()
    end
  end
end

function M:close_term(name)
  local term = model:find_terminal_by_name(name)
  if term then
    close_term_base(term)
  else
    print('No terminal "'..name..'" exists.')
  end
end

function M:close_current_term()
  if model.current_term then
    close_term_base(model.current_term)
  end
end

function M:cycle_term(rel_ind)
  local new_term = model:find_relative_term(rel_ind)
  if new_term then
    model.current_term = new_term
    ui:show_terminal(new_term, float_terminal_options.term_cmd, float_terminal_options.auto_enter)
  end
end

-- Leaving as a bit of a placeholder
function M:handle_term_close()
  M:close_current_term()
end

return M
