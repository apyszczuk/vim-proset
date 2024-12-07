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

function! proset#lib#dict#get_not_empty(dictionary, default_value, ...)
    let l:ret = trim(call(function('proset#lib#dict#get'),
    \                       [a:dictionary, a:default_value] + a:000))
    if empty(l:ret)
        let l:ret = a:default_value
    endif
    return l:ret
endfunction

function! proset#lib#dict#remove_if_exists(dictionary, key)
    if has_key(a:dictionary, a:key)
        call remove(a:dictionary, a:key)
    endif
endfunction
