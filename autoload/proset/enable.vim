if exists("g:autoloaded_proset_enable")
    finish
endif
let g:autoloaded_proset_enable = 1

function! proset#enable#enable(settings)
    if a:settings.is_project()
        call a:settings.enable()
    endif
endfunction

function! proset#enable#disable(settings)
    if a:settings.is_project()
        call a:settings.disable()
    endif
endfunction
