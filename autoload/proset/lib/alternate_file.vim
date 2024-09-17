if exists("g:autoloaded_proset_lib_alternate_file")
    finish
endif
let g:autoloaded_proset_lib_alternate_file = 1

let s:extensions = {}

function! s:find_filename(extensions)
    let l:current_extension      = expand('%:e')
    let l:current_filename_noext = expand('%:r')

    for l:ext in keys(a:extensions)
        if l:current_extension ==# l:ext
            let l:fn = l:current_filename_noext . "." . a:extensions[l:ext]
            if filereadable(l:fn)
                return l:fn
            endif
            break
        endif
    endfor
    return ""
endfunction

function! s:open_in_current_window(filename)
    if empty(a:filename)
        return
    endif

    " TODO open file or buffer?
    throw ":e " . a:filename
endfunction

function! s:open_in_some_split_window(filename, command_buffer, command_file)
    if empty(a:filename)
        return
    endif

    if buflisted(a:filename) == 1
        let l:winnr = bufwinnr(a:filename)
        let l:cmd = ':' . l:winnr . "wincmd w"
        if l:winnr == -1
            let l:cmd = ":" . a:command_buffer . " " . a:filename
        endif
        throw l:cmd
    endif

    throw ":" . a:command_file . " " . a:filename
endfunction

function! s:open_in_split_window(filename)
    call s:open_in_some_split_window(a:filename, "sb", "spl")
endfunction

function! s:open_in_vsplit_window(filename)
    call s:open_in_some_split_window(a:filename, "vert sb", "vspl")
endfunction

function! s:swap_dict_kv(dict)
    let l:ret = {}
    for [l:k, l:v] in items(a:dict)
        let l:ret[l:v] = l:k
    endfor
    return l:ret
endfunction

function! s:handle(extensions, open_function)
    try
        call a:open_function(s:find_filename(a:extensions))
        call a:open_function(s:find_filename(s:swap_dict_kv(a:extensions)))
    catch
        execute v:exception
    endtry
endfunction

function! proset#lib#alternate_file#current_window()
    call s:handle(s:extensions, function('s:open_in_current_window'))
endfunction

function! proset#lib#alternate_file#split_window()
    call s:handle(s:extensions, function('s:open_in_split_window'))
endfunction

function! proset#lib#alternate_file#vsplit_window()
    call s:handle(s:extensions, function('s:open_in_vsplit_window'))
endfunction

function! proset#lib#alternate_file#add_extensions_pair(first_extension,
        \ second_extension)
    let s:extensions[a:first_extension] = a:second_extension
endfunction

function! proset#lib#alternate_file#remove_extensions_pair(first_extension)
    call remove(s:extensions, a:first_extension)
endfunction
