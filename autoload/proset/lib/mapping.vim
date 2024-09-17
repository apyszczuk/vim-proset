if exists("g:autoloaded_proset_lib_mapping")
    finish
endif
let g:autoloaded_proset_lib_mapping = 1

function! proset#lib#mapping#set_nnoremap_silent_mapping(cmd, seq)
    execute "nnoremap <silent> " . a:seq . " " . a:cmd
endfunction

function! proset#lib#mapping#set_nnoremap_mapping(cmd, seq)
    execute "nnoremap " . a:seq . " " . a:cmd
endfunction

function! proset#lib#mapping#add_mappings(dict)
    for i in keys(a:dict)
        call function(a:dict[i]["function"])(a:dict[i]["sequence"])
    endfor
endfunction

function! proset#lib#mapping#remove_mappings(dict)
    for i in keys(a:dict)
        execute "unmap " . a:dict[i]["sequence"]
    endfor
endfunction
