if exists("g:autoloaded_proset_close")
    finish
endif
let g:autoloaded_proset_close = 1

function! proset#close#close(settings)
    autocmd! Proset DirChangedPre *
    let l:project_name  = a:settings.get_project_name()
    let l:is_project    = a:settings.is_project()
    let l:settings_name = a:settings.get_settings_name()

    call proset#enable#disable(a:settings)
    let l:ret               = {}
    let l:ret.settings      = proset#settings#default#construct()
    let l:ret.configuration = {}

    if l:is_project
        call proset#print#print_info(l:settings_name, l:project_name . " was closed")
    endif

    return l:ret
endfunction
