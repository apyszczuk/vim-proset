if exists("g:autoloaded_proset_utils_cscope")
    finish
endif
let g:autoloaded_proset_utils_cscope = 1

function! s:get_files_string(dir)
    let l:ret = ""

    for entry in readdirex(a:dir)
        let l:found_path = a:dir . "/" . entry.name

        if entry.type == "file" &&
        \  entry.name =~ '\v^.*\.(h|hh|hxx|hpp|c|cc|cxx|cpp|H|HH|HXX|HPP|C|CC|CXX|CPP)$'
            let l:ret .= l:found_path . " "
        elseif entry.type == "dir"
            let l:ret .= s:get_files_string(l:found_path)
        endif
    endfor

    return l:ret
endfunction

function! proset#utils#cscope#get_cscope_command(source_directory,
        \ additional_cscope_directories,
        \ temporary_cscope_file)
    let l:cwd = getcwd() . "/"
    let l:files = s:get_files_string(l:cwd . a:source_directory)
    for l:item in split(a:additional_cscope_directories, ";")
        let l:files .= s:get_files_string(l:cwd . l:item)
    endfor

    return "cscope -Rb -f " . a:temporary_cscope_file . " " . l:files
endfunction

function! proset#utils#cscope#remove_all_connections()
    :cs kill -1
endfunction

function! proset#utils#cscope#add_cscope_files(temporary_cscope_file,
        \ external_cscope_files)
    call proset#utils#cscope#remove_all_connections()
    let l:fns = [a:temporary_cscope_file] + split(a:external_cscope_files, ";")
    for l:fn in l:fns
        silent execute "cs add " . l:fn
    endfor
endfunction
