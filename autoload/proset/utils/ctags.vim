if exists("g:autoloaded_proset_utils_ctags")
    finish
endif
let g:autoloaded_proset_utils_ctags = 1

function! proset#utils#ctags#get_ctags_command(additional_ctags_directories,
        \ build_directory,
        \ temporary_ctags_file)
    let l:cmd = "ctags -R " .
                \ "--exclude=" . a:build_directory . " " .
                \ "--c++-kinds=+p " .
                \ "--fields=+iaS " .
                \ "--extras=+q " .
                \ "--tag-relative=yes " .
                \ "-f " . a:temporary_ctags_file . " " .
                \ ". " .
                \ substitute(a:additional_ctags_directories, ";", " ", "g")
    return l:cmd
endfunction

function! proset#utils#ctags#get_tags_filenames(temporary_ctags_file,
        \ external_ctags_files)
    let l:ret   = a:temporary_ctags_file
    let l:files = substitute(a:external_ctags_files, ";", ",", "g")
    if !empty(l:files)
        let l:ret .= "," . l:files
    endif
    return l:ret
endfunction
