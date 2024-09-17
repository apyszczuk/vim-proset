if exists("g:autoloaded_proset_utils_path")
    finish
endif
let g:autoloaded_proset_utils_path = 1

function! proset#utils#path#is_subpath(base, path)
    let l:base = simplify(fnamemodify(trim(a:base), ":p"))
    let l:path = simplify(fnamemodify(trim(a:path), ":p"))

    return (match(l:path, l:base) == 0) &&
        \ (len(l:path) > len(l:base)) &&
        \ !isabsolutepath(a:path)
endfunction

function! proset#utils#path#get_subpath(dictionary, default_value, ...)
    let l:ret = call(function('proset#lib#dict#get_not_empty'),
    \                   [a:dictionary, a:default_value] + a:000)
    if proset#utils#path#is_subpath(getcwd(), l:ret) == 0
        let l:ret = a:default_value
    endif
    return l:ret
endfunction

