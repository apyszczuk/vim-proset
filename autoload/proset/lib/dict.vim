if exists("g:autoloaded_proset_lib_dict")
    finish
endif
let g:autoloaded_proset_lib_dict = 1

function! proset#lib#dict#get(dictionary, default_value, ...)
    if empty(a:000) || empty(a:dictionary)
        return a:default_value
    endif

    let l:dict  = a:dictionary
    let l:ret   = ""

    for l:item in a:000
        if !has_key(l:dict, l:item)
            return a:default_value
        endif
        let l:ret  = l:dict[l:item]
        let l:dict = l:ret
    endfor

    return l:ret
endfunction
