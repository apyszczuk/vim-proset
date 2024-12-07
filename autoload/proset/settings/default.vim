if exists("g:autoloaded_proset_settings_default")
    finish
endif
let g:autoloaded_proset_settings_default = 1

let s:default = {}

function! s:default.is_project()
    return 0
endfunction

function! s:default.get_project_name()
    return ""
endfunction

function! s:default.get_properties()
    return {}
endfunction

function! s:default.get_settings_name()
    return ""
endfunction

function! s:default.enable()
endfunction

function! s:default.disable()
endfunction

function! s:default.create(project_path, args)
endfunction

function! proset#settings#default#construct()
    return s:default
endfunction
