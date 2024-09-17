if exists("g:autoloaded_proset_settings_cxx_cmake_cmake")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_cmake = 1

function! s:get_pattern_value(project_file, pattern)
    let l:ret_val = ""
    if !filereadable(a:project_file)
        return l:ret_val
    endif

    let l:do_the_job = '0'
    for l:item in readfile(a:project_file)
        let l:item = trim(l:item)

        if empty(l:item) || (l:item[0] == "#")
            continue
        endif

        if l:item =~# a:pattern
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

function! s:get_project_name(project_file)
    return s:get_pattern_value(a:project_file, 'set\s*(PROJECT_NAME')
endfunction

function! s:get_output_dir(project_file, pattern)
    let l:ret = s:get_pattern_value(a:project_file, a:pattern)
    if !empty(l:ret)
        throw l:ret
    endif
endfunction

function! s:get_output_directory(project_file, build_directory)
    try
        call s:get_output_dir(a:project_file,
        \       'set\s*(CMAKE_RUNTIME_OUTPUT_DIRECTORY')
        call s:get_output_dir(a:project_file,
        \       'set\s*(CMAKE_ARCHIVE_OUTPUT_DIRECTORY')
        call s:get_output_dir(a:project_file,
        \       'set\s*(CMAKE_LIBRARY_OUTPUT_DIRECTORY')
    catch
        let l:val    = v:exception
        let l:prefix = "${PROJECT_SOURCE_DIR}/"

        if l:val =~# (l:prefix . '.*')
            return strpart(l:val, len(l:prefix))
        else
            return a:build_directory . "/" . l:val
        endif
    endtry

    return a:build_directory
endfunction

let s:object = {"properties": {}}

function! s:get_cmake_properties(config,
    \       build_directory,
    \       source_directory,
    \       proset_settings_file)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.input_file       = "CMakeLists.txt"

    let l:ret.settings.project_name     =
    \ s:get_project_name(l:ret.settings.input_file)

    let l:ret.settings.bin_directory    =
    \ s:get_output_directory(l:ret.settings.input_file, a:build_directory)

    let l:ret.settings.is_project       =
    \ filereadable(l:ret.settings.input_file) &&
    \ isdirectory(a:source_directory) &&
    \ filereadable(a:proset_settings_file) &&
    \ !empty(l:ret.settings.project_name)

    return l:ret
endfunction

function! s:object.get_properties()
    return self.properties
endfunction

function! s:object.enable()
endfunction

function! s:object.disable()
endfunction

function! proset#settings#cxx_cmake#cmake#construct(config,
    \       build_directory,
    \       source_directory,
    \       proset_settings_file)
    let l:ret               = deepcopy(s:object)
    let l:ret.properties    = s:get_cmake_properties(a:config,
    \                           a:build_directory,
    \                           a:source_directory,
    \                           a:proset_settings_file)

    return l:ret
endfunction
