if exists("g:autoloaded_proset_print")
    finish
endif
let g:autoloaded_proset_print = 1

function! s:print(message)
    echohl WarningMsg | echom a:message | echohl None
endfunction

function! proset#print#print_info(settings_name, message)
    call s:print("proset(" . a:settings_name . "): " . a:message . ".")
endfunction

function! proset#print#print_error(error_number, message)
    call s:print("proset-E" . a:error_number . ": " . a:message . ".")
endfunction
