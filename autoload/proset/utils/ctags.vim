if exists("g:autoloaded_proset_utils_ctags")
    finish
endif
let g:autoloaded_proset_utils_ctags = 1

function! proset#utils#ctags#get_ctags_command(source_directory,
        \ additional_ctags_directories,
        \ temporary_ctags_file)
    let l:cmd = "ctags -R " .
                \ "--c++-kinds=+p " .
                \ "--fields=+iaS " .
                \ "--extras=+q " .
                \ "--tag-relative=yes " .
                \ "-f " . a:temporary_ctags_file . " " .
                \ a:source_directory . " " .
                \ substitute(a:additional_ctags_directories, ";", " ", "g")
    return l:cmd
endfunction

function! proset#utils#ctags#get_ctags_filenames(temporary_ctags_file,
        \ external_ctags_files)
    let l:ret   = a:temporary_ctags_file
    let l:files = substitute(a:external_ctags_files, ";", ",", "g")
    if !empty(l:files)
        let l:ret .= "," . l:files
    endif
    return l:ret
endfunction
