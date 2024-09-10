if exists("g:autoloaded_proset_utils_mapping")
    finish
endif
let g:autoloaded_proset_utils_mapping = 1

function! proset#utils#mapping#set_nnoremap_silent_mapping(cmd, seq)
    execute "nnoremap <silent> " . a:seq . " " . a:cmd
endfunction

function! proset#utils#mapping#set_nnoremap_mapping(cmd, seq)
    execute "nnoremap " . a:seq . " " . a:cmd
endfunction

function! proset#utils#mapping#add_mappings(dict)
    for i in keys(a:dict)
        call function(a:dict[i]["function"])(a:dict[i]["sequence"])
    endfor
endfunction

function! proset#utils#mapping#remove_mappings(dict)
    for i in keys(a:dict)
        execute "unmap " . a:dict[i]["sequence"]
    endfor
endfunction
