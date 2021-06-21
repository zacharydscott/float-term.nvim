command! FloatTermToggle lua require('float-term'):float_toggle()
command! FloatTermOpen lua require('float-term'):float_open()
command! FloatTermClose lua require('float-term'):float_close()
command! -nargs=1 FloatTermCycle lua require('float-term'):cycle_term(<q-args>)
command! -nargs=1 FloatTermSwitch lua require('float-term'):switch_term([[args]])
command! -nargs=? FloatTermAdd lua require('float-term'):add_term([[<args>]])
command! -nargs=? FloatTermRemove lua require('float-term'):remove_term([[<args>]])
command! -nargs=1 FloatTermRename lua require('float-term'):rename_current_term([[<args>]])