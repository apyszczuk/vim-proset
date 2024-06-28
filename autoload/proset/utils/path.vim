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
