if exists("g:autoloaded_proset_utils_cscope")
    finish
endif
let g:autoloaded_proset_utils_cscope = 1

function! proset#utils#cscope#get_cscope_command(
            \ additional_cscope_directories,
            \ temporary_cscope_file)
    let l:ext = ""
    for l:item in split(a:additional_cscope_directories, ";")
        let l:ext .= " -s " . l:item
    endfor

    let l:cmd = "cscope -Rb " .
                \ "-f " . a:temporary_cscope_file .
                \ l:ext
    return l:cmd
endfunction

function! proset#utils#cscope#remove_all_connections()
    :cs kill -1
endfunction

function! proset#utils#cscope#add_cscope_files(
            \ temporary_cscope_file,
            \ external_cscope_files)
    call proset#utils#cscope#remove_all_connections()
    let l:files = [a:temporary_cscope_file] + split(a:external_cscope_files, ";")
    for l:fn in l:files
        silent execute "cs add " . l:fn
    endfor
endfunction
