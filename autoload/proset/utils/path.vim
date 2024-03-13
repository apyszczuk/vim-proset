if exists("g:autoloaded_proset_utils_path")
    finish
endif
let g:autoloaded_proset_utils_path = 1

function! proset#utils#path#is_local_path(path)
    let l:path = simplify(a:path)

    if empty(l:path)
        return 0
    endif

    if (match(l:path, '\.') == 0) && (len(l:path) == 1)
        return 0
    endif

    if match(l:path, '\./') == 0
        return 0
    endif

    if match(l:path, '\') >= 0
        return 0
    endif

    if match(l:path, '\.\.') >= 0
        return 0
    endif

    if isabsolutepath(l:path)
        return 0
    endif

    return 1
endfunction
