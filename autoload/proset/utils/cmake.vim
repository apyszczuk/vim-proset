if exists("g:autoloaded_proset_utils_cmake")
    finish
endif
let g:autoloaded_proset_utils_cmake = 1

function! proset#utils#cmake#get_project_name(project_file)
    let l:ret_val = ""
    if !filereadable(a:project_file)
        return l:ret_val
    endif

    let l:do_the_job = '0'
    for l:item in readfile(a:project_file)
        if l:item =~# 'set\s*(PROJECT_NAME'
            let l:ret_val = ""
            for l:char in split(l:item, '\zs')
                if l:char == '"' && l:do_the_job == '0'
                    let l:do_the_job = '1'
                    continue
                elseif l:char == '"' && l:do_the_job == '1'
                    let l:do_the_job = '0'
                    break
                endif

                if l:do_the_job == '1'
                    let l:ret_val .= l:char
                endif
            endfor
            break
        endif
    endfor
    return l:ret_val
endfunction

function! proset#utils#cmake#get_build_command(build_directory, jobs_number)
    let l:cmd = "cmake\\ " .
                \ "-B" . a:build_directory . "\\ " .
                \ ".\\ " .
                \ "&&\\ " .
                \ "cmake\\ --build\\ " . a:build_directory . "\\ " .
                \ "--\\ " .
                \ "-j" . a:jobs_number
    return l:cmd
endfunction
