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

function! s:generate_tags_file(source_directory,
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

function! s:create_header_command(open_mode,
    \       project_name,
    \       header_extension,
    \       source_extension,
    \       path)
    return s:create_file_command("s:create_header_file",
    \       "CXXCMakeHeaderCreatedEvent",
    \       a:open_mode,
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension,
    \       a:path)
endfunction

function! s:create_source_command(open_mode,
    \       project_name,
    \       header_extension,
    \       source_extension,
    \       path)
    return s:create_file_command("s:create_source_file",
    \       "CXXCMakeSourceCreatedEvent",
    \       a:open_mode,
    \       a:project_name,
    \       a:source_extension,
    \       a:header_extension,
    \       a:path)
endfunction

function! s:create_header_source_command(open_mode,
    \       project_name,
    \       header_extension,
    \       source_extension,
    \       path)
    let l:open_modes = split(a:open_mode, ";", 1)

    call s:create_header_command(l:open_modes[0],
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension,
    \       a:path)

    call s:create_source_command(l:open_modes[1],
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension,
    \       a:path)
endfunction

function! s:register_create_file_command(command_name,
    \       create_function,
    \       open_mode,
    \       project_name,
    \       header_extension,
    \       source_extension)
    execute 'command! -complete=file -nargs=1 ' . a:command_name . ' '
    \       . 'call ' . a:create_function . '('
    \       . '"' . a:open_mode . '", '
    \       . '"' . a:project_name . '", '
    \       . '"' . a:header_extension . '", '
    \       . '"' . a:source_extension . '", '
    \       . '"<args>")'
endfunction

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

function! s:cxx_cmake_build_fn()
    :update | :AsyncRun -program=make -post=call\ <SID>post_build_task()
endfunction

function! s:register_update_symbols_command(source_directory,
    \       additional_ctags_directories,
    \       temporary_ctags_file,
    \       additional_cscope_directories,
    \       temporary_cscope_file,
    \       external_cscope_files)
    let l:cmd = ':call <SID>generate_tags_file(' .
    \           '"' . a:source_directory . '", ' .
    \           '"' . a:additional_ctags_directories . '", ' .
    \           '"' . a:temporary_ctags_file . '"' .
    \           ') ' .
    \           "\| :call <SID>generate_cscope_file(" .
    \           '"' . a:source_directory . '", ' .
    \           '"' . a:additional_cscope_directories . '", ' .
    \           '"' . a:temporary_cscope_file . '"' .
    \           ') ' .
    \           "\| :call proset#utils#cscope#add_cscope_files(" .
    \           '"' . a:temporary_cscope_file . '", ' .
    \           '"' . a:external_cscope_files . '"' .
    \           ') ' .
    \           "\| :redraw!"

    execute "command! -nargs=0 CXXCMakeUpdateSymbols " . l:cmd
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
    command! -nargs=0 CXXCMakeBuild :call s:cxx_cmake_build_fn()

    execute "command! -nargs=* CXXCMakeRun "
    \       . "term " . a:bin_directory . "/" . a:project_name . " <args>"

    execute "command! -nargs=0 CXXCMakeClean "
    \       . "call delete(\"" . a:build_directory . "\", \"rf\")"

    command -nargs=0 CXXCMakeCleanAndBuild {
        :CXXCMakeClean
        :CXXCMakeBuild
    }

    call s:register_update_symbols_command(a:source_directory,
    \       a:additional_ctags_directories,
    \       a:temporary_ctags_file,
    \       a:additional_cscope_directories,
    \       a:temporary_cscope_file,
    \       a:external_cscope_files)

    command! -nargs=0 CXXCMakeAlternateFileCurrentWindow {
        :call proset#utils#alternate_file#current_window()
    }

    command! -nargs=0 CXXCMakeAlternateFileSplitWindow {
        :call proset#utils#alternate_file#split_window()
    }

    command! -nargs=0 CXXCMakeAlternateFileVSplitWindow {
        :call proset#utils#alternate_file#vsplit_window()
    }

    call s:register_create_file_command(
    \       "CXXCMakeCreateHeader",
    \       "<SID>create_header_command",
    \       "",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateHeaderEdit",
    \       "<SID>create_header_command",
    \       ":e",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateHeaderEditSplit",
    \       "<SID>create_header_command",
    \       ":spl",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateHeaderEditVSplit",
    \       "<SID>create_header_command",
    \       ":vspl",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)

    call s:register_create_file_command(
    \       "CXXCMakeCreateSource",
    \       "<SID>create_source_command",
    \       "",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateSourceEdit",
    \       "<SID>create_source_command",
    \       ":e",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateSourceEditSplit",
    \       "<SID>create_source_command",
    \       ":spl",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateSourceEditVSplit",
    \       "<SID>create_source_command",
    \       ":vspl",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)

    call s:register_create_file_command(
    \       "CXXCMakeCreateHeaderSource",
    \       "<SID>create_header_source_command",
    \       ";",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateHeaderSourceEditSplit",
    \       "<SID>create_header_source_command",
    \       ":spl;:spl",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateHeaderSourceEditCurrentSplit",
    \       "<SID>create_header_source_command",
    \       ":e;:spl",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateHeaderSourceEditVSplit",
    \       "<SID>create_header_source_command",
    \       ":vspl;:vspl",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
    call s:register_create_file_command(
    \       "CXXCMakeCreateHeaderSourceEditCurrentVSplit",
    \       "<SID>create_header_source_command",
    \       ":e;:vspl",
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
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

function! s:add_mappings(mappings)
    for key in keys(a:mappings)
        let l:dict = a:mappings[key]
        let l:seq  = l:dict["seq"]
        if (!empty(l:seq))
            call l:dict["fun"](l:seq)
        endif
    endfor
endfunction

function! s:remove_commands()
    for l:cmd in getcompletion("CXXCMake", "command")
        execute "delcommand " . l:cmd
    endfor
endfunction

function! s:remove_mappings(mappings)
    for l:key in keys(a:mappings)
        let l:seq  = a:mappings[l:key]["seq"]
        if !empty(l:seq)
            execute "unmap " . l:seq
        endif
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

function! s:cxx_cmake.construct(config)
    let l:ret = deepcopy(self)

    let l:ret.properties.settings =
    \ {
    \   "jobs_number":
    \   proset#lib#dict#get(a:config,
    \       "1",
    \       "build",
    \       "settings",
    \       "jobs"
    \   ),
    \
    \   "temporary_directory":
    \   s:get_correct_path(a:config,
    \       ".vim-proset_tmp",
    \       "temporary_directory"
    \   ),
    \   "build_directory":
    \   s:get_correct_path(a:config,
    \       "build",
    \       "build",
    \       "settings",
    \       "build_directory"
    \   ),
    \   "source_directory":
    \   s:get_correct_path(a:config,
    \       "src",
    \       "source",
    \       "settings",
    \       "source_directory"
    \   ),
    \
    \   "additional_ctags_directories":
    \   join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "symbols",
    \       "settings",
    \       "additional_ctags_directories"
    \   ), ";"),
    \   "additional_cscope_directories":
    \   join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "symbols",
    \       "settings",
    \       "additional_cscope_directories"
    \   ), ";"),
    \   "additional_search_directories":
    \   join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "source",
    \       "settings",
    \       "additional_search_directories"
    \   ), ";"),
    \
    \   "external_cscope_files":
    \   join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "symbols",
    \       "settings",
    \       "external_cscope_files"
    \   ), ";"),
    \   "external_ctags_files":
    \   join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "symbols",
    \       "settings",
    \       "external_ctags_files"
    \   ), ";"),
    \
    \   "header_extension":
    \   s:get_not_empty(a:config,
    \       "hpp",
    \       "source",
    \       "settings",
    \       "header_extension"
    \   ),
    \   "source_extension":
    \   s:get_not_empty(a:config,
    \       "cpp",
    \       "source",
    \       "settings",
    \       "source_extension"
    \   ),
    \ }

    let l:cmakelists_file = "CMakeLists.txt"
    let l:project_name = proset#utils#cmake#get_project_name(l:cmakelists_file)

    let l:ret.properties.internal =
    \ {
    \   "temporary_ctags_file":
    \   l:ret.properties.settings.temporary_directory . "/tags",
    \
    \   "temporary_cscope_file":
    \   l:ret.properties.settings.temporary_directory . "/cscope",
    \
    \   "project_name":
    \   l:project_name,
    \
    \   "bin_directory":
    \   proset#utils#cmake#get_output_directory(l:cmakelists_file,
    \       l:ret.properties.settings.build_directory),
    \
    \   "is_project":
    \   filereadable(l:cmakelists_file) &&
    \   isdirectory(l:ret.properties.settings.source_directory) &&
    \   filereadable(g:proset_settings_file) &&
    \   !empty(l:project_name)
    \ }

    call proset#utils#alternate_file#add_extensions_pair(
    \       l:ret.properties.settings.header_extension,
    \       l:ret.properties.settings.source_extension)

    let l:ret.properties.mappings =
    \ {
    \   "alternate_file.current_window":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "alternate_file",
    \           "mappings",
    \           "current_window"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_silent_mapping",
    \           [":CXXCMakeAlternateFileCurrentWindow<CR>"]
    \       )
    \   },
    \   "alternate_file.split_window":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "alternate_file",
    \           "mappings",
    \           "split_window"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_silent_mapping",
    \           [":CXXCMakeAlternateFileSplitWindow<CR>"]
    \       )
    \   },
    \   "alternate_file.vsplit_window":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "alternate_file",
    \           "mappings",
    \           "vsplit_window"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_silent_mapping",
    \           [":CXXCMakeAlternateFileVSplitWindow<CR>"]
    \       )
    \   },
    \
    \   "cscope.a_assignments":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "cscope",
    \           "a_assignments"
    \       ),
    \       "fun":
    \       function("s:set_cscope_mapping",
    \           ["a"]
    \       )
    \   },
    \   "cscope.c_functions_calling":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "cscope",
    \           "c_functions_calling"
    \       ),
    \       "fun":
    \       function("s:set_cscope_mapping",
    \           ["c"]
    \       )
    \   },
    \   "cscope.d_functions_called_by":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "cscope",
    \           "d_functions_called_by"
    \       ),
    \       "fun":
    \       function("s:set_cscope_mapping",
    \           ["d"]
    \       )
    \   },
    \   "cscope.e_egrep":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "cscope",
    \           "e_egrep"
    \       ),
    \       "fun":
    \       function("s:set_cscope_mapping",
    \           ["e"]
    \       )
    \   },
    \   "cscope.f_file":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "cscope",
    \           "f_file"
    \       ),
    \       "fun":
    \       function("s:set_cscope_mapping",
    \           ["f"]
    \       )
    \   },
    \   "cscope.g_definition":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "cscope",
    \           "g_definition"
    \       ),
    \       "fun":
    \       function("s:set_cscope_mapping",
    \           ["g"]
    \       )
    \   },
    \   "cscope.i_including":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "cscope",
    \           "i_including"
    \       ),
    \       "fun":
    \       function("s:set_cscope_mapping",
    \           ["i"]
    \       )
    \   },
    \   "cscope.s_symbol":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "cscope",
    \           "s_symbol"
    \       ),
    \       "fun":
    \       function("s:set_cscope_mapping",
    \           ["s"]
    \       )
    \   },
    \   "cscope.t_string":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "cscope",
    \           "t_string"
    \       ),
    \       "fun":
    \       function("s:set_cscope_mapping",
    \           ["t"]
    \       )
    \   },
    \
    \   "build":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "build",
    \           "mappings",
    \           "build"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_silent_mapping",
    \           [":CXXCMakeBuild<CR>"]
    \       )
    \   },
    \   "clean":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "build",
    \           "mappings",
    \           "clean"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_silent_mapping",
    \           [":CXXCMakeClean<CR>"]
    \       )
    \   },
    \   "clean_and_build":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "build",
    \           "mappings",
    \           "clean_and_build"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_silent_mapping",
    \           [":CXXCMakeCleanAndBuild<CR>"]
    \       )
    \   },
    \   "run":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "run",
    \           "mappings",
    \           "run"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_silent_mapping",
    \           [":CXXCMakeRun<CR>"]
    \       )
    \   },
    \   "run_args":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "run",
    \           "mappings",
    \           "run_args"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeRun "]
    \       )
    \   },
    \
    \   "update_symbols":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "symbols",
    \           "mappings",
    \           "update_symbols"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_silent_mapping",
    \           [":CXXCMakeUpdateSymbols<CR>"]
    \       )
    \   },
    \
    \   "create_header":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_header",
    \           "mappings",
    \           "create"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateHeader "]
    \       )
    \   },
    \   "create_header_edit":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_header",
    \           "mappings",
    \           "create_edit"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateHeaderEdit "]
    \       )
    \   },
    \   "create_header_edit_split":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_header",
    \           "mappings",
    \           "create_edit_split"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateHeaderEditSplit "]
    \       )
    \   },
    \   "create_header_edit_vsplit":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_header",
    \           "mappings",
    \           "create_edit_vsplit"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateHeaderEditVSplit "]
    \       )
    \   },
    \   "create_source":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_source",
    \           "mappings",
    \           "create"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateSource "]
    \       )
    \   },
    \   "create_source_edit":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_source",
    \           "mappings",
    \           "create_edit"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateSourceEdit "]
    \       )
    \   },
    \   "create_source_edit_split":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_source",
    \           "mappings",
    \           "create_edit_split"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateSourceEditSplit "]
    \       )
    \   },
    \   "create_source_edit_vsplit":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_source",
    \           "mappings",
    \           "create_edit_vsplit"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateSourceEditVSplit "]
    \       )
    \   },
    \   "create_header_source":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_header_source",
    \           "mappings",
    \           "create"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateHeaderSource "]
    \       )
    \   },
    \   "create_header_source_edit_split":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_header_source",
    \           "mappings",
    \           "create_edit_split"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateHeaderSourceEditSplit "]
    \       )
    \   },
    \   "create_header_source_edit_current_split":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_header_source",
    \           "mappings",
    \           "create_edit_current_split"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateHeaderSourceEditCurrentSplit "]
    \       )
    \   },
    \   "create_header_source_edit_vsplit":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_header_source",
    \           "mappings",
    \           "create_edit_vsplit"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateHeaderSourceEditVSplit "]
    \       )
    \   },
    \   "create_header_source_edit_current_vsplit":
    \   {
    \       "seq":
    \       proset#lib#dict#get(a:config,
    \           "",
    \           "create_header_source",
    \           "mappings",
    \           "create_edit_current_vsplit"
    \       ),
    \       "fun":
    \       function("s:set_nnoremap_mapping",
    \           [":CXXCMakeCreateHeaderSourceEditCurrentVSplit "]
    \       )
    \   },
    \ }

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
    let l:s = self.properties.settings
    let l:p = self.properties.internal

    let s:options_initial_values =
    \ {
    \   "makeprg":    &makeprg,
    \   "tags":       &tags,
    \   "path":       &path,
    \ }

    call delete(l:s.temporary_directory, "rf")
    call mkdir(l:s.temporary_directory, "p")

    call s:set_makeprg(l:s.build_directory, l:s.jobs_number)
    call s:add_commands(l:s.source_directory,
    \       l:s.build_directory,
    \       l:p.bin_directory,
    \       l:p.project_name,
    \       l:s.additional_ctags_directories,
    \       l:p.temporary_ctags_file,
    \       l:s.additional_cscope_directories,
    \       l:p.temporary_cscope_file,
    \       l:s.external_cscope_files,
    \       l:s.header_extension,
    \       l:s.source_extension)
    call s:add_mappings(self.properties.mappings)

    let &tags = proset#utils#ctags#get_tags_filenames(l:p.temporary_ctags_file,
    \               l:s.external_ctags_files)
    call s:generate_tags_file(l:s.source_directory,
    \       l:s.additional_ctags_directories,
    \       l:p.temporary_ctags_file)
    call s:generate_cscope_file(l:s.source_directory,
    \       l:s.additional_cscope_directories,
    \       l:p.temporary_cscope_file)
    call proset#utils#cscope#add_cscope_files(l:p.temporary_cscope_file,
    \       l:s.external_cscope_files)
    let &path .= substitute(l:s.additional_search_directories, ";", ",", "g")
endfunction

function! s:cxx_cmake.disable()
    let &path       = s:options_initial_values.path
    let &tags       = s:options_initial_values.tags
    let &makeprg    = s:options_initial_values.makeprg

    call proset#utils#cscope#remove_all_connections()
    call s:remove_mappings(self.properties.mappings)
    call s:remove_commands()

    call delete(self.properties.settings.temporary_directory, "rf")
endfunction

autocmd User ProsetRegisterInternalSettingsEvent
    \ call ProsetRegisterSettings("cxx-cmake", "CXXCMakeConstruct")

function! CXXCMakeConstruct(config)
    return s:cxx_cmake.construct(a:config)
endfunction
