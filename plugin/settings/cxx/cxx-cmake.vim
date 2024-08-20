" cxx-cmake - CXX CMake Settings Dictionary
"
" Author:     Artur Pyszczuk <apyszczuk@gmail.com>
" License:    Same terms as Vim itself
" Website:    https://github.com/apyszczuk/vim-proset

if exists("g:loaded_proset_settings_cxx_cxx_cmake")
    finish
endif
let g:loaded_proset_settings_cxx_cxx_cmake = 1

let s:cxx_cmake = {'properties': {}}

function! s:generate_ctags_file(source_directory,
    \       additional_ctags_directories,
    \       temporary_ctags_file)
    let l:cmd = proset#utils#ctags#get_ctags_command(a:source_directory,
    \               a:additional_ctags_directories,
    \               a:temporary_ctags_file)
    silent execute '!' . l:cmd
endfunction

function! s:generate_cscope_file(source_directory,
    \       additional_cscope_directories,
    \       temporary_cscope_file)
    let l:cmd = proset#utils#cscope#get_cscope_command(a:source_directory,
    \               a:additional_cscope_directories,
    \               a:temporary_cscope_file)
    silent execute "!" . l:cmd
endfunction

function! s:set_makeprg(build_directory, jobs_number)
    let l:cmd = proset#utils#cmake#get_build_command(a:build_directory,
    \               a:jobs_number)
    silent execute "set makeprg=" . l:cmd
endfunction

function! s:create_file(create_function,
    \       project_name,
    \       extension,
    \       other_extension,
    \       path)
    if a:path[len(a:path)-1] == "/"
        echoerr "(" . s:cxx_cmake.get_settings_name() . "): "
        \       . "Need file name, not directory name."
        return ""
    endif

    if mkdir(fnamemodify(a:path, ":h"), "p") == 0
        return ""
    endif

    let l:path = fnamemodify(a:path, ":r") . "." . a:extension

    let Fun = function(a:create_function)
    return Fun(a:project_name, l:path, a:other_extension)
endfunction

function! s:prepare_header_guard_string(project_name, path)
    let l:path = substitute(a:path, "/", "_", "g")
    let l:path = substitute(l:path, "-", "_", "g")
    let l:path = substitute(l:path, '\.', "_", "g")

    return toupper(a:project_name . "_" . l:path)
endfunction

function! s:create_header_file(project_name, path, source_extension)
    let l:guard_string = s:prepare_header_guard_string(a:project_name, a:path)

    let l:file_content  = "#ifndef " . l:guard_string . "\n"
    let l:file_content .= "#define " . l:guard_string . "\n\n\n"
    let l:file_content .= "#endif // " . l:guard_string

    if writefile(split(l:file_content, "\n"), a:path) == -1
        return ""
    endif
    return a:path
endfunction

function! s:create_source_file(project_name, path, header_extension)
    let l:header_path = fnamemodify(a:path, ":t:r") . "." . a:header_extension
    let l:file_content = "#include \"" . l:header_path . "\"\n"
    if writefile(split(l:file_content, "\n"), a:path) == -1
        return ""
    endif
    return a:path
endfunction

function! s:create_file_command(create_function,
    \       user_command,
    \       open_mode,
    \       project_name,
    \       extension,
    \       other_extension,
    \       path)
    let l:path = s:create_file(a:create_function,
    \               a:project_name,
    \               a:extension,
    \               a:other_extension,
    \               a:path)
    if empty(l:path)
        return
    endif

    if !empty(a:open_mode)
        execute a:open_mode . " " . l:path
    endif

    if exists('#User#' . a:user_command)
        execute 'doautocmd User ' . a:user_command
    endif
endfunction

function! s:create_header_command(open_mode, input, path)
    return s:create_file_command("s:create_header_file",
    \       "CXXCMakeHeaderCreatedEvent",
    \       a:open_mode,
    \       a:input.project_name,
    \       a:input.header_extension,
    \       a:input.source_extension,
    \       a:path)
endfunction

function! s:create_source_command(open_mode, input, path)
    return s:create_file_command("s:create_source_file",
    \       "CXXCMakeSourceCreatedEvent",
    \       a:open_mode,
    \       a:input.project_name,
    \       a:input.source_extension,
    \       a:input.header_extension,
    \       a:path)
endfunction

function! s:create_header_source_command(open_mode, input, path)
    let l:open_modes = split(a:open_mode, ";", 1)

    call s:create_header_command(l:open_modes[0], a:input, a:path)
    call s:create_source_command(l:open_modes[1], a:input, a:path)

endfunction

function! s:add_update_ctags_symbols_command(source_directory,
    \       additional_ctags_directories,
    \       temporary_ctags_file)
    function! s:update_ctags_symbols_command_impl(redraw) closure
        call s:generate_ctags_file(a:source_directory,
        \       a:additional_ctags_directories,
        \       a:temporary_ctags_file)

        if empty(a:redraw)
            :redraw!
        endif
    endfunction

    command! -nargs=? CXXCMakeUpdateCtagsSymbols
    \   call s:update_ctags_symbols_command_impl(<q-args>)
endfunction

function! s:add_update_cscope_symbols_command(source_directory,
    \       additional_cscope_directories,
    \       temporary_cscope_file,
    \       external_cscope_files)
    function! s:update_cscope_symbols_command_impl(redraw) closure
        call s:generate_cscope_file(a:source_directory,
        \       a:additional_cscope_directories,
        \       a:temporary_cscope_file)

        call proset#utils#cscope#add_cscope_files(a:temporary_cscope_file,
        \       a:external_cscope_files)

        if empty(a:redraw)
            :redraw!
        endif
    endfunction

    command! -nargs=? CXXCMakeUpdateCscopeSymbols
    \   call s:update_cscope_symbols_command_impl(<q-args>)
endfunction

function! s:add_run_command(bin_directory, project_name)
    function! s:run_command_impl(arg) closure
        let l:cmd = a:bin_directory . "/" . a:project_name . " " . a:arg
        call term_start(l:cmd)
    endfunction

    command! -nargs=* CXXCMakeRun call s:run_command_impl(<q-args>)
endfunction

function! s:add_build_command()
    function! s:post_build_task()
        let l:msg = "Success: "
        let l:st  = 0

        if g:asyncrun_code != 0
            let l:msg = "Failure: "
            let l:st  = 1
        else
            let l:list = getqflist()
            for item in l:list
                if item["valid"] == 1
                    let l:st = 1
                    break
                endif
            endfor
        endif

        echo l:msg . &makeprg
        if l:st == 0
            :ccl
        endif
    endfunction

    function! s:build_command_impl()
        :update
        :AsyncRun -program=make -post=call\ <SID>post_build_task()
    endfunction

    command! -nargs=0 CXXCMakeBuild call s:build_command_impl()
endfunction

function! s:add_clean_command(build_directory)
    function! s:clean_command_impl() closure
        call delete(a:build_directory, "rf")
    endfunction

    command! -nargs=0 CXXCMakeClean call s:clean_command_impl()
endfunction

function! s:add_clean_and_build_command()
    function! s:clean_and_build_command_impl()
        :CXXCMakeClean
        :CXXCMakeBuild
    endfunction

    command -nargs=0 CXXCMakeCleanAndBuild call s:clean_and_build_command_impl()
endfunction

function! s:add_update_symbols_command()
    function! s:update_symbols_command_impl()
        :CXXCMakeUpdateCtagsSymbols 0
        :CXXCMakeUpdateCscopeSymbols 0
        :redraw!
    endfunction

    command -nargs=0 CXXCMakeUpdateSymbols call s:update_symbols_command_impl()
endfunction

function! s:add_alternate_file_current_window_command()
    function! s:alternate_file_current_window_command_impl()
        call proset#utils#alternate_file#current_window()
    endfunction

    command! -nargs=0 CXXCMakeAlternateFileCurrentWindow
    \ call s:alternate_file_current_window_command_impl()
endfunction

function! s:add_alternate_file_split_window_command()
    function! s:alternate_file_split_window_command_impl()
        call proset#utils#alternate_file#split_window()
    endfunction

    command! -nargs=0 CXXCMakeAlternateFileSplitWindow
    \ call s:alternate_file_split_window_command_impl()
endfunction

function! s:add_alternate_file_vsplit_window_command()
    function! s:alternate_file_vsplit_window_command_impl()
        call proset#utils#alternate_file#vsplit_window()
    endfunction

    command! -nargs=0 CXXCMakeAlternateFileVSplitWindow
    \ call s:alternate_file_vsplit_window_command_impl()
endfunction

function! s:add_create_header_command(input_dict)
    function! s:create_header_command_impl(path) closure
        call s:create_header_command("", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeader
    \   call s:create_header_command_impl(<f-args>)
endfunction

function! s:add_create_header_edit_command(input_dict)
    function! s:create_header_edit_command_impl(path) closure
        call s:create_header_command(":e", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderEdit
    \   call s:create_header_edit_command_impl(<f-args>)
endfunction

function! s:add_create_header_edit_split_command(input_dict)
    function! s:create_header_edit_split_command_impl(path) closure
        call s:create_header_command(":spl", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderEditSplit
    \   call s:create_header_edit_split_command_impl(<f-args>)
endfunction

function! s:add_create_header_edit_vsplit_command(input_dict)
    function! s:create_header_edit_vsplit_command_impl(path) closure
        call s:create_header_command(":vspl", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderEditVSplit
    \   call s:create_header_edit_vsplit_command_impl(<f-args>)
endfunction

function! s:add_create_source_command(input_dict)
    function! s:create_source_command_impl(path) closure
        call s:create_source_command("", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateSource
    \   call s:create_source_command_impl(<f-args>)
endfunction

function! s:add_create_source_edit_command(input_dict)
    function! s:create_source_edit_command_impl(path) closure
        call s:create_source_command(":e", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateSourceEdit
    \   call s:create_source_edit_command_impl(<f-args>)
endfunction

function! s:add_create_source_edit_split_command(input_dict)
    function! s:create_source_edit_split_command_impl(path) closure
        call s:create_source_command(":spl", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateSourceEditSplit
    \   call s:create_source_edit_split_command_impl(<f-args>)
endfunction

function! s:add_create_source_edit_vsplit_command(input_dict)
    function! s:create_source_edit_vsplit_command_impl(path) closure
        call s:create_source_command(":vspl", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateSourceEditVSplit
    \   call s:create_source_edit_vsplit_command_impl(<f-args>)
endfunction

function! s:add_create_header_source_command(input_dict)
    function! s:create_header_source_command_impl(path) closure
        call s:create_header_source_command(";", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderSource
    \   call s:create_header_source_command_impl(<f-args>)
endfunction

function! s:add_create_header_source_edit_split_command(input_dict)
    function! s:create_header_source_edit_split_command_impl(path) closure
        call s:create_header_source_command(":spl;:spl", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderSourceEditSplit
    \   call s:create_header_source_edit_split_command_impl(<f-args>)
endfunction

function! s:add_create_header_source_edit_vsplit_command(input_dict)
    function! s:create_header_source_edit_vsplit_command_impl(path) closure
        call s:create_header_source_command(":vspl;:vspl", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderSourceEditVSplit
    \   call s:create_header_source_edit_vsplit_command_impl(<f-args>)
endfunction

function! s:add_create_header_source_edit_current_split_command(input_dict)
    function! s:create_header_source_edit_current_split_command_impl(path) closure
        call s:create_header_source_command(":e;:spl", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderSourceEditCurrentSplit
    \   call s:create_header_source_edit_current_split_command_impl(<f-args>)
endfunction

function! s:add_create_header_source_edit_current_vsplit_command(input_dict)
    function! s:create_header_source_edit_current_vsplit_command_impl(path) closure
        call s:create_header_source_command(":e;:vspl", a:input_dict, a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderSourceEditCurrentVSplit
    \   call s:create_header_source_edit_current_vsplit_command_impl(<f-args>)
endfunction

function! s:add_commands(source_directory,
    \       build_directory,
    \       bin_directory,
    \       project_name,
    \       additional_ctags_directories,
    \       temporary_ctags_file,
    \       additional_cscope_directories,
    \       temporary_cscope_file,
    \       external_cscope_files,
    \       header_extension,
    \       source_extension)

    call s:add_build_command()
    call s:add_run_command(a:bin_directory, a:project_name)
    call s:add_clean_command(a:build_directory)
    call s:add_clean_and_build_command()

    call s:add_update_ctags_symbols_command(a:source_directory,
    \       a:additional_ctags_directories,
    \       a:temporary_ctags_file)

    call s:add_update_cscope_symbols_command(a:source_directory,
    \       a:additional_cscope_directories,
    \       a:temporary_cscope_file,
    \       a:external_cscope_files)

    call s:add_update_symbols_command()
    call s:add_alternate_file_current_window_command()
    call s:add_alternate_file_split_window_command()
    call s:add_alternate_file_vsplit_window_command()

    const l:create_input =
    \ {
    \   "project_name":         a:project_name,
    \   "header_extension":     a:header_extension,
    \   "source_extension":     a:source_extension
    \ }

    call s:add_create_header_command(l:create_input)
    call s:add_create_header_edit_command(l:create_input)
    call s:add_create_header_edit_split_command(l:create_input)
    call s:add_create_header_edit_vsplit_command(l:create_input)

    call s:add_create_source_command(l:create_input)
    call s:add_create_source_edit_command(l:create_input)
    call s:add_create_source_edit_split_command(l:create_input)
    call s:add_create_source_edit_vsplit_command(l:create_input)

    call s:add_create_header_source_command(l:create_input)
    call s:add_create_header_source_edit_split_command(l:create_input)
    call s:add_create_header_source_edit_vsplit_command(l:create_input)
    call s:add_create_header_source_edit_current_split_command(l:create_input)
    call s:add_create_header_source_edit_current_vsplit_command(l:create_input)

endfunction

function! s:set_cscope_mapping(cmd, seq)
    execute "nnoremap <silent> " . a:seq
    \       . " :cs find " . a:cmd . ' <C-R>=expand("<cword>")<CR><CR>'
endfunction

function! s:set_nnoremap_silent_mapping(cmd, seq)
    execute "nnoremap <silent> " . a:seq . " " . a:cmd
endfunction

function! s:set_nnoremap_mapping(cmd, seq)
    execute "nnoremap " . a:seq . " " . a:cmd
endfunction

function! s:remove_commands()
    for l:cmd in getcompletion("CXXCMake", "command")
        execute "delcommand " . l:cmd
    endfor
endfunction

function! s:prepare_list_of_mappings(dict)
    const l:mappings_str = "mappings"

    let l:ret = []
    for i in keys(a:dict)
        let l:top_key = a:dict[i]

        if (type(l:top_key) == v:t_dict)
        \   && (has_key(l:top_key, l:mappings_str))
        \   && (!empty(l:top_key[l:mappings_str]))

            for j in keys(l:top_key[l:mappings_str])
                let l:data = l:top_key[l:mappings_str][j]
                if !empty(l:data.sequence)
                    call add(l:ret, l:data) " sequence and function
                endif
            endfor

        endif
    endfor

    return l:ret
endfunction

function s:add_mappings(lst)
    for i in a:lst
        call function(i["function"])(i["sequence"])
    endfor
endfunction

function s:remove_mappings(lst)
    for i in a:lst
        execute "unmap " . i["sequence"]
    endfor
endfunction

function! s:get_not_empty(config, default_value, ...)
    let l:ret = trim(call(function('proset#lib#dict#get'),
    \                       [a:config, a:default_value] + a:000))
    if empty(l:ret)
        let l:ret = a:default_value
    endif
    return l:ret
endfunction


function! s:get_correct_path(config, default_value, ...)
    let l:ret = call(function('s:get_not_empty'),
    \                   [a:config, a:default_value] + a:000)
    if proset#utils#path#is_subpath(getcwd(), l:ret) == 0
        let l:ret = a:default_value
    endif
    return l:ret
endfunction

function! s:create_top_level_configuration_dictionary(config)
    let l:ret = {}

    let l:ret.proset_settings =
    \ proset#lib#dict#get(a:config,
    \   "",
    \   "proset_settings"
    \ )

    let l:ret.temporary_directory =
    \ s:get_correct_path(a:config,
    \   ".vim-proset_tmp",
    \   "temporary_directory"
    \ )

    return l:ret
endfunction

function! s:create_build_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.build_directory =
    \ s:get_correct_path(a:config,
    \   "build",
    \   "build",
    \   "settings",
    \   "build_directory"
    \ )

    let l:ret.settings.jobs =
    \ proset#lib#dict#get(a:config,
    \   "1",
    \   "build",
    \   "settings",
    \   "jobs"
    \ )

    let l:ret.mappings.build =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "build",
    \       "mappings",
    \       "build"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeBuild<CR>"]
    \   )
    \ }

    let l:ret.mappings.clean =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "build",
    \       "mappings",
    \       "clean"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeClean<CR>"]
    \   )
    \ }

    let l:ret.mappings.clean_and_build =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "build",
    \       "mappings",
    \       "clean_and_build"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeCleanAndBuild<CR>"]
    \   )
    \ }

    return l:ret
endfunction

function! s:create_run_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.mappings.run =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "run",
    \       "mappings",
    \       "run"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeRun<CR>"]
    \   )
    \ }

    let l:ret.mappings.run_args =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "run",
    \       "mappings",
    \       "run_args"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeRun "]
    \   )
    \ }

    return l:ret
endfunction

function! s:create_source_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.source_directory =
    \ s:get_correct_path(a:config,
    \   "src",
    \   "source",
    \   "settings",
    \   "source_directory"
    \ )

    let l:ret.settings.header_extension =
    \ s:get_not_empty(a:config,
    \   "hpp",
    \   "source",
    \   "settings",
    \   "header_extension"
    \ )

    let l:ret.settings.source_extension =
    \ s:get_not_empty(a:config,
    \   "cpp",
    \   "source",
    \   "settings",
    \   "source_extension"
    \ )

    let l:ret.settings.additional_search_directories =
    \ join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "source",
    \       "settings",
    \       "additional_search_directories"
    \   ),
    \   ";"
    \ )

    return l:ret
endfunction

function! s:create_ctags_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.additional_ctags_directories =
    \ join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "ctags",
    \       "settings",
    \       "additional_ctags_directories"
    \   ),
    \   ";"
    \ )

    let l:ret.settings.external_ctags_files =
    \ join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "ctags",
    \       "settings",
    \       "external_ctags_files"
    \   ),
    \   ";"
    \ )

    let l:ret.mappings.update_ctags_symbols =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "ctags",
    \       "mappings",
    \       "update_ctags_symbols"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeUpdateCtagsSymbols<CR>"]
    \   )
    \ }

    return l:ret
endfunction

function! s:create_cscope_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.additional_cscope_directories =
    \ join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "cscope",
    \       "settings",
    \       "additional_cscope_directories"
    \   ),
    \   ";"
    \ )

    let l:ret.settings.external_cscope_files =
    \ join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "cscope",
    \       "settings",
    \       "external_cscope_files"
    \   ),
    \   ";"
    \ )

    let l:ret.mappings.update_cscope_symbols =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "update_cscope_symbols"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeUpdateCscopeSymbols<CR>"]
    \   )
    \ }

    let l:ret.mappings.a_assignments =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "a_assignments"
    \   ),
    \   "function":
    \   function("s:set_cscope_mapping",
    \       ["a"]
    \   )
    \ }

    let l:ret.mappings.c_functions_calling =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "c_functions_calling"
    \   ),
    \   "function":
    \   function("s:set_cscope_mapping",
    \       ["c"]
    \   )
    \ }

    let l:ret.mappings.d_functions_called_by =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "d_functions_called_by"
    \   ),
    \   "function":
    \   function("s:set_cscope_mapping",
    \       ["d"]
    \   )
    \ }

    let l:ret.mappings.e_egrep =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "e_egrep"
    \   ),
    \   "function":
    \   function("s:set_cscope_mapping",
    \       ["e"]
    \   )
    \ }

    let l:ret.mappings.f_file =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "f_file"
    \   ),
    \   "function":
    \   function("s:set_cscope_mapping",
    \       ["f"]
    \   )
    \ }

    let l:ret.mappings.g_definition =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "g_definition"
    \   ),
    \   "function":
    \   function("s:set_cscope_mapping",
    \       ["g"]
    \   )
    \ }

    let l:ret.mappings.i_including =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "i_including"
    \   ),
    \   "function":
    \   function("s:set_cscope_mapping",
    \       ["i"]
    \   )
    \ }

    let l:ret.mappings.s_symbol =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "s_symbol"
    \   ),
    \   "function":
    \   function("s:set_cscope_mapping",
    \       ["s"]
    \   )
    \ }

    let l:ret.mappings.t_string =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "cscope",
    \       "mappings",
    \       "t_string"
    \   ),
    \   "function":
    \   function("s:set_cscope_mapping",
    \       ["t"]
    \   )
    \ }

    return l:ret
endfunction

function! s:create_symbols_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.mappings.update_symbols =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "symbols",
    \       "mappings",
    \       "update_symbols"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeUpdateSymbols<CR>"]
    \   )
    \ }

    return l:ret
endfunction

function! s:create_alternate_file_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.mappings.current_window =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "alternate_file",
    \       "mappings",
    \       "current_window"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeAlternateFileCurrentWindow<CR>"]
    \   )
    \ }

    let l:ret.mappings.split_window =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "alternate_file",
    \       "mappings",
    \       "split_window"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeAlternateFileSplitWindow<CR>"]
    \   )
    \ }

    let l:ret.mappings.vsplit_window =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "alternate_file",
    \       "mappings",
    \       "vsplit_window"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_silent_mapping",
    \       [":CXXCMakeAlternateFileVSplitWindow<CR>"]
    \   )
    \ }

    return l:ret
endfunction

function! s:create_create_header_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.mappings.create =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_header",
    \       "mappings",
    \       "create"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeader "]
    \   )
    \ }

    let l:ret.mappings.create_edit =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_header",
    \       "mappings",
    \       "create_edit"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderEdit "]
    \   )
    \ }

    let l:ret.mappings.create_edit_split =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_header",
    \       "mappings",
    \       "create_edit_split"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderEditSplit "]
    \   )
    \ }

    let l:ret.mappings.create_edit_vsplit =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_header",
    \       "mappings",
    \       "create_edit_vsplit"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderEditVSplit "]
    \   )
    \ }

    return l:ret
endfunction

function! s:create_create_source_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.mappings.create =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_source",
    \       "mappings",
    \       "create"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateSource "]
    \   )
    \ }

    let l:ret.mappings.create_edit =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_source",
    \       "mappings",
    \       "create_edit"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateSourceEdit "]
    \   )
    \ }

    let l:ret.mappings.create_edit_split =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_source",
    \       "mappings",
    \       "create_edit_split"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateSourceEditSplit "]
    \   )
    \ }

    let l:ret.mappings.create_edit_vsplit =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_source",
    \       "mappings",
    \       "create_edit_vsplit"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateSourceEditVSplit "]
    \   )
    \ }

    return l:ret
endfunction

function! s:create_create_header_source_configuration_dictionary(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.mappings.create =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_header_source",
    \       "mappings",
    \       "create"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderSource "]
    \   )
    \ }

    let l:ret.mappings.create_edit_split =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_header_source",
    \       "mappings",
    \       "create_edit_split"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderSourceEditSplit "]
    \   )
    \ }

    let l:ret.mappings.create_edit_current_split =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_header_source",
    \       "mappings",
    \       "create_edit_current_split"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderSourceEditCurrentSplit "]
    \   )
    \ }

    let l:ret.mappings.create_edit_vsplit =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_header_source",
    \       "mappings",
    \       "create_edit_vsplit"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderSourceEditVSplit "]
    \   )
    \ }

    let l:ret.mappings.create_edit_current_vsplit =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "create_header_source",
    \       "mappings",
    \       "create_edit_current_vsplit"
    \   ),
    \   "function":
    \   function("s:set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderSourceEditCurrentVSplit "]
    \   )
    \ }

    return l:ret
endfunction

function! s:cxx_cmake.construct(config)
    let l:ret = deepcopy(self)

    let l:ret.properties.configuration =
    \ {
    \   "build":
    \   s:create_build_configuration_dictionary(a:config),
    \   "run":
    \   s:create_run_configuration_dictionary(a:config),
    \   "source":
    \   s:create_source_configuration_dictionary(a:config),
    \   "ctags":
    \   s:create_ctags_configuration_dictionary(a:config),
    \   "cscope":
    \   s:create_cscope_configuration_dictionary(a:config),
    \   "symbols":
    \   s:create_symbols_configuration_dictionary(a:config),
    \   "alternate_file":
    \   s:create_alternate_file_configuration_dictionary(a:config),
    \   "create_header":
    \   s:create_create_header_configuration_dictionary(a:config),
    \   "create_source":
    \   s:create_create_source_configuration_dictionary(a:config),
    \   "create_header_source":
    \   s:create_create_header_source_configuration_dictionary(a:config),
    \ }

    let l:ret.properties.configuration =
    \ extend(l:ret.properties.configuration,
    \       s:create_top_level_configuration_dictionary(a:config))

    let l:cmakelists_file = "CMakeLists.txt"
    let l:project_name = proset#utils#cmake#get_project_name(l:cmakelists_file)

    let l:ret.properties.internal =
    \ {
    \   "temporary_ctags_file":
    \   l:ret.properties.configuration.temporary_directory . "/ctags",
    \
    \   "temporary_cscope_file":
    \   l:ret.properties.configuration.temporary_directory . "/cscope",
    \
    \   "project_name":
    \   l:project_name,
    \
    \   "bin_directory":
    \   proset#utils#cmake#get_output_directory(l:cmakelists_file,
    \       l:ret.properties.configuration.build.settings.build_directory),
    \
    \   "is_project":
    \   filereadable(l:cmakelists_file) &&
    \   isdirectory(l:ret.properties.configuration.source.settings.source_directory) &&
    \   filereadable(g:proset_settings_file) &&
    \   !empty(l:project_name)
    \ }

    call proset#utils#alternate_file#add_extensions_pair(
    \       l:ret.properties.configuration.source.settings.header_extension,
    \       l:ret.properties.configuration.source.settings.source_extension)

    return l:ret
endfunction

function! s:cxx_cmake.is_project()
    return self.properties.internal.is_project
endfunction

function! s:cxx_cmake.get_project_name()
    return self.properties.internal.project_name
endfunction

function! s:cxx_cmake.get_properties()
    return self.properties
endfunction

function! s:cxx_cmake.get_settings_name()
    return "cxx-cmake"
endfunction

function! s:cxx_cmake.enable() abort
    let l:s = self.properties.configuration
    let l:p = self.properties.internal

    let s:options_initial_values =
    \ {
    \   "makeprg":    &makeprg,
    \   "tags":       &tags,
    \   "path":       &path,
    \ }

    call delete(l:s.temporary_directory, "rf")
    call mkdir(l:s.temporary_directory, "p")

    call s:set_makeprg(l:s.build.settings.build_directory,
    \       l:s.build.settings.jobs)
    call s:add_commands(l:s.source.settings.source_directory,
    \       l:s.build.settings.build_directory,
    \       l:p.bin_directory,
    \       l:p.project_name,
    \       l:s.ctags.settings.additional_ctags_directories,
    \       l:p.temporary_ctags_file,
    \       l:s.cscope.settings.additional_cscope_directories,
    \       l:p.temporary_cscope_file,
    \       l:s.cscope.settings.external_cscope_files,
    \       l:s.source.settings.header_extension,
    \       l:s.source.settings.source_extension)
    call s:add_mappings(s:prepare_list_of_mappings(l:s))

    let &tags = proset#utils#ctags#get_ctags_filenames(l:p.temporary_ctags_file,
    \               l:s.ctags.settings.external_ctags_files)
    call s:generate_ctags_file(l:s.source.settings.source_directory,
    \       l:s.ctags.settings.additional_ctags_directories,
    \       l:p.temporary_ctags_file)
    call s:generate_cscope_file(l:s.source.settings.source_directory,
    \       l:s.cscope.settings.additional_cscope_directories,
    \       l:p.temporary_cscope_file)
    call proset#utils#cscope#add_cscope_files(l:p.temporary_cscope_file,
    \       l:s.cscope.settings.external_cscope_files)
    let &path .= substitute(l:s.source.settings.additional_search_directories,
    \               ";",
    \               ",",
    \               "g")
endfunction

function! s:cxx_cmake.disable()
    let l:s = self.properties.configuration

    let &path       = s:options_initial_values.path
    let &tags       = s:options_initial_values.tags
    let &makeprg    = s:options_initial_values.makeprg

    call proset#utils#cscope#remove_all_connections()
    call s:remove_mappings(s:prepare_list_of_mappings(l:s))
    call s:remove_commands()

    call delete(l:s.temporary_directory, "rf")
endfunction

autocmd User ProsetRegisterInternalSettingsEvent
    \ call ProsetRegisterSettings("cxx-cmake", "CXXCMakeConstruct")

function! CXXCMakeConstruct(config)
    return s:cxx_cmake.construct(a:config)
endfunction
