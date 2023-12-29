if exists("g:loaded_proset_settings_cxx_cxx_cmake")
    finish
endif
let g:loaded_proset_settings_cxx_cxx_cmake = 1

let s:cxx_cmake = {'properties': {}}

function! s:generate_tags_file(additional_ctags_directories, build_directory, temporary_ctags_file)
    let l:cmd = proset#utils#ctags#get_ctags_command(
                \ a:additional_ctags_directories,
                \ a:build_directory,
                \ a:temporary_ctags_file)
    silent execute '!' . l:cmd
endfunction

function! s:generate_cscope_file(additional_cscope_directories, temporary_cscope_file)
    silent execute "!" . proset#utils#cscope#get_cscope_command(
                \ a:additional_cscope_directories,
                \ a:temporary_cscope_file)
endfunction

function! s:set_makeprg(build_directory, jobs_number)
    let l:cmd = proset#utils#cmake#get_build_command(a:build_directory, a:jobs_number)
    silent execute "set makeprg=" . l:cmd
endfunction

function! s:create_file(create_function,
            \ project_name,
            \ extension,
            \ other_extension,
            \ path)
    if a:path[len(a:path)-1] == "/"
        echoerr "(" . s:cxx_cmake.get_settings_name() . "): Need file name, not directory name."
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
            \ user_command,
            \ open_mode,
            \ project_name,
            \ extension,
            \ other_extension,
            \ path)
    let l:path = s:create_file(a:create_function,
                \ a:project_name,
                \ a:extension,
                \ a:other_extension,
                \ a:path)
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
            \ project_name,
            \ header_extension,
            \ source_extension,
            \ path)
    return s:create_file_command("s:create_header_file",
                \ "CXXCMakeHeaderCreatedEvent",
                \ a:open_mode,
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension,
                \ a:path)
endfunction

function! s:create_source_command(open_mode,
            \ project_name,
            \ header_extension,
            \ source_extension,
            \ path)
    return s:create_file_command("s:create_source_file",
                \ "CXXCMakeSourceCreatedEvent",
                \ a:open_mode,
                \ a:project_name,
                \ a:source_extension,
                \ a:header_extension,
                \ a:path)
endfunction

function! s:create_header_source_command(open_mode,
            \ project_name,
            \ header_extension,
            \ source_extension,
            \ path)
    call s:create_header_command(a:open_mode,
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension,
                \ a:path)
    call s:create_source_command(a:open_mode,
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension,
                \ a:path)
endfunction

function! s:register_create_file_command(command_name,
            \ create_function,
            \ open_mode,
            \ project_name,
            \ header_extension,
            \ source_extension)
    execute 'command! -complete=file -nargs=1 ' . a:command_name . ' '
                \ . 'call ' . a:create_function . '('
                \ . '"' . a:open_mode . '", '
                \ . '"' . a:project_name . '", '
                \ . '"' . a:header_extension . '", '
                \ . '"' . a:source_extension . '", '
                \ . '"<args>")'
endfunction

function! s:add_commands(build_directory,
            \ project_name,
            \ additional_ctags_directories,
            \ temporary_ctags_file,
            \ additional_cscope_directories,
            \ temporary_cscope_file,
            \ external_cscope_files,
            \ header_extension,
            \ source_extension)
    execute "command! -nargs=0 CXXCMakeBuild " . ":AsyncRun -program=make"
    execute "command! -nargs=* CXXCMakeRun "   . "term " . a:build_directory . "/" . a:project_name . " <args>"
    execute "command! -nargs=0 CXXCMakeClean " . "call delete(\"" . a:build_directory . "\", \"rf\")"

    let l:update_symbols_cmd = ':call <SID>generate_tags_file(' .
                \ '"' . a:additional_ctags_directories . '", ' .
                \ '"' . a:build_directory . '", ' .
                \ '"' . a:temporary_ctags_file . '"' .
                \ ') ' .
                \ "\| :call <SID>generate_cscope_file(" .
                \ '"' . a:additional_cscope_directories . '", ' .
                \ '"' . a:temporary_cscope_file . '"' .
                \ ') ' .
                \ "\| :call proset#utils#cscope#add_cscope_files(" .
                \ '"' . a:temporary_cscope_file . '", ' .
                \ '"' . a:external_cscope_files . '"' .
                \ ') ' .
                \ "\| :redraw!"
    execute "command! -nargs=0 CXXCMakeUpdateCtagsCscopeSymbols " . l:update_symbols_cmd
    execute "command! -nargs=0 CXXCMakeAlternateFileCurrentWindow :call proset#utils#alternate_file#current_window()"
    execute "command! -nargs=0 CXXCMakeAlternateFileSplitWindow   :call proset#utils#alternate_file#split_window()"
    execute "command! -nargs=0 CXXCMakeAlternateFileVSplitWindow  :call proset#utils#alternate_file#vsplit_window()"

    call s:register_create_file_command("CXXCMakeCreateHeader",
                \ "<SID>create_header_command",
                \ "",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)
    call s:register_create_file_command("CXXCMakeCreateHeaderEdit",
                \ "<SID>create_header_command",
                \ ":e",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)
    call s:register_create_file_command("CXXCMakeCreateHeaderEditSplit",
                \ "<SID>create_header_command",
                \ ":spl",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)
    call s:register_create_file_command("CXXCMakeCreateHeaderEditVSplit",
                \ "<SID>create_header_command",
                \ ":vspl",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)

    call s:register_create_file_command("CXXCMakeCreateSource",
                \ "<SID>create_source_command",
                \ "",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)
    call s:register_create_file_command("CXXCMakeCreateSourceEdit",
                \ "<SID>create_source_command",
                \ ":e",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)
    call s:register_create_file_command("CXXCMakeCreateSourceEditSplit",
                \ "<SID>create_source_command",
                \ ":spl",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)
    call s:register_create_file_command("CXXCMakeCreateSourceEditVSplit",
                \ "<SID>create_source_command",
                \ ":vspl",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)

    call s:register_create_file_command("CXXCMakeCreateHeaderSource",
                \ "<SID>create_header_source_command",
                \ "",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)
    call s:register_create_file_command("CXXCMakeCreateHeaderSourceEditSplit",
                \ "<SID>create_header_source_command",
                \ ":spl",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)
    call s:register_create_file_command("CXXCMakeCreateHeaderSourceEditVSplit",
                \ "<SID>create_header_source_command",
                \ ":vspl",
                \ a:project_name,
                \ a:header_extension,
                \ a:source_extension)
endfunction

function! s:set_cscope_mapping(cmd, seq)
    execute "nnoremap <silent> " . a:seq . " :cs find " . a:cmd . ' <C-R>=expand("<cword>")<CR><CR>'
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

function! s:get_string_non_empty(config, key, default_value)
    let l:ret = a:config.get(a:key, a:default_value)
    if empty(l:ret)
        throw "proset:settings:cxx:" . s:cxx_cmake.get_settings_name() . ":" . a:key . " is empty"
    endif
    return l:ret
endfunction

function! s:cxx_cmake.construct(config)
    let l:ret = deepcopy(self)

    let l:ret.properties["settings_directory"]              = g:proset_directory
    let l:ret.properties["temporary_directory"]             = s:get_string_non_empty(a:config, "temporary_directory", ".project_tmp")

    let l:ret.properties["build_directory"]                 = s:get_string_non_empty(a:config, "build_directory", "build")
    let l:ret.properties["source_directory"]                = s:get_string_non_empty(a:config, "source_directory", "src")
    let l:ret.properties["jobs_number"]                     = a:config.get("jobs_number", "1")

    let l:ret.properties["temporary_ctags_file"]            = l:ret.properties["temporary_directory"] . "/tags"
    let l:ret.properties["additional_ctags_directories"]    = a:config.get("additional_ctags_directories", "")
    let l:ret.properties["external_ctags_files"]            = a:config.get("external_ctags_files", "")

    let l:ret.properties["temporary_cscope_file"]           = l:ret.properties["temporary_directory"] . "/cscope"
    let l:ret.properties["additional_cscope_directories"]   = a:config.get("additional_cscope_directories", "")
    let l:ret.properties["external_cscope_files"]           = a:config.get("external_cscope_files", "")

    let l:ret.properties["additional_search_directories"]   = a:config.get("additional_search_directories", "")

    let l:ret.properties["cmakelists_file"]                 = "CMakeLists.txt"
    let l:ret.properties["project_name"]                    = proset#utils#cmake#get_project_name(l:ret.properties["cmakelists_file"])
    let l:ret.properties["is_project"]                      = filereadable(l:ret.properties["cmakelists_file"]) &&
                                                            \ isdirectory(l:ret.properties["source_directory"]) &&
                                                            \ isdirectory(l:ret.properties["settings_directory"])


    let l:ret.properties["header_extension"]                = s:get_string_non_empty(a:config, "header_extension", "hpp")
    let l:ret.properties["source_extension"]                = s:get_string_non_empty(a:config, "source_extension", "cpp")

    call proset#utils#alternate_file#add_extensions_pair(
                \ l:ret.properties["header_extension"],
                \ l:ret.properties["source_extension"])

    let l:ret.properties["mappings"] =
    \ {
    \   "alternate_file.current_window":
    \   {
    \       "seq": a:config.get("mappings.alternate_file.current_window", ""),
    \       "fun": function("s:set_nnoremap_silent_mapping", [":CXXCMakeAlternateFileCurrentWindow<CR>"])
    \   },
    \   "alternate_file.split_window":
    \   {
    \       "seq": a:config.get("mappings.alternate_file.split_window", ""),
    \       "fun": function("s:set_nnoremap_silent_mapping", [":CXXCMakeAlternateFileSplitWindow<CR>"])
    \   },
    \   "alternate_file.vsplit_window":
    \   {
    \       "seq": a:config.get("mappings.alternate_file.vsplit_window", ""),
    \       "fun": function("s:set_nnoremap_silent_mapping", [":CXXCMakeAlternateFileVSplitWindow<CR>"])
    \   },
    \
    \   "cscope.a_find_assignments_to_this_symbol":
    \   {
    \       "seq": a:config.get("mappings.cscope.a_find_assignments_to_this_symbol", ""),
    \       "fun": function("s:set_cscope_mapping", ["a"])
    \   },
    \   "cscope.c_find_functions_calling_this_function":
    \   {
    \       "seq": a:config.get("mappings.cscope.c_find_functions_calling_this_function", ""),
    \       "fun": function("s:set_cscope_mapping", ["c"])
    \   },
    \   "cscope.d_find_functions_called_by_this_function":
    \   {
    \       "seq": a:config.get("mappings.cscope.d_find_functions_called_by_this_function", ""),
    \       "fun": function("s:set_cscope_mapping", ["d"])
    \   },
    \   "cscope.e_find_this_egrep_pattern":
    \   {
    \       "seq": a:config.get("mappings.cscope.e_find_this_egrep_pattern", ""),
    \       "fun": function("s:set_cscope_mapping", ["e"])
    \   },
    \   "cscope.f_find_this_file":
    \   {
    \       "seq": a:config.get("mappings.cscope.f_find_this_file", ""),
    \       "fun": function("s:set_cscope_mapping", ["f"])
    \   },
    \   "cscope.g_find_this_definition":
    \   {
    \       "seq": a:config.get("mappings.cscope.g_find_this_definition", ""),
    \       "fun": function("s:set_cscope_mapping", ["g"])
    \   },
    \   "cscope.i_find_files_including_this_file":
    \   {
    \       "seq": a:config.get("mappings.cscope.i_find_files_including_this_file", ""),
    \       "fun": function("s:set_cscope_mapping", ["i"])
    \   },
    \   "cscope.s_find_this_c_symbol":
    \   {
    \       "seq": a:config.get("mappings.cscope.s_find_this_c_symbol", ""),
    \       "fun": function("s:set_cscope_mapping", ["s"])
    \   },
    \   "cscope.t_find_this_text_string":
    \   {
    \       "seq": a:config.get("mappings.cscope.t_find_this_text_string", ""),
    \       "fun": function("s:set_cscope_mapping", ["t"])
    \   },
    \
    \   "build":
    \   {
    \       "seq": a:config.get("mappings.build", ""),
    \       "fun": function("s:set_nnoremap_silent_mapping", [":CXXCMakeBuild<CR>"])
    \   },
    \   "clean_and_build":
    \   {
    \       "seq": a:config.get("mappings.clean_and_build", ""),
    \       "fun": function("s:set_nnoremap_silent_mapping", [":CXXCMakeClean<CR> :CXXCMakeBuild<CR>"])
    \   },
    \   "run":
    \   {
    \       "seq": a:config.get("mappings.run", ""),
    \       "fun": function("s:set_nnoremap_silent_mapping", [":CXXCMakeRun<CR>"])
    \   },
    \   "run_args":
    \   {
    \       "seq": a:config.get("mappings.run_args", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeRun "])
    \   },
    \   "update_cscope_ctags":
    \   {
    \       "seq": a:config.get("mappings.update_ctags_cscope_symbols", ""),
    \       "fun": function("s:set_nnoremap_silent_mapping", [":CXXCMakeUpdateCtagsCscopeSymbols<CR>"])
    \   },
    \   "create_header":
    \   {
    \       "seq": a:config.get("mappings.create_header", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateHeader "])
    \   },
    \   "create_header_edit":
    \   {
    \       "seq": a:config.get("mappings.create_header_edit", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateHeaderEdit "])
    \   },
    \   "create_header_edit_split":
    \   {
    \       "seq": a:config.get("mappings.create_header_edit_split", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateHeaderEditSplit "])
    \   },
    \   "create_header_edit_vsplit":
    \   {
    \       "seq": a:config.get("mappings.create_header_edit_vsplit", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateHeaderEditVSplit "])
    \   },
    \   "create_source":
    \   {
    \       "seq": a:config.get("mappings.create_source", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateSource "])
    \   },
    \   "create_source_edit":
    \   {
    \       "seq": a:config.get("mappings.create_source_edit", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateSourceEdit "])
    \   },
    \   "create_source_edit_split":
    \   {
    \       "seq": a:config.get("mappings.create_source_edit_split", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateSourceEditSplit "])
    \   },
    \   "create_source_edit_vsplit":
    \   {
    \       "seq": a:config.get("mappings.create_source_edit_vsplit", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateSourceEditVSplit "])
    \   },
    \   "create_header_source":
    \   {
    \       "seq": a:config.get("mappings.create_header_source", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateHeaderSource "])
    \   },
    \   "create_header_source_edit_split":
    \   {
    \       "seq": a:config.get("mappings.create_header_source_edit_split", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateHeaderSourceEditSplit "])
    \   },
    \   "create_header_source_edit_vsplit":
    \   {
    \       "seq": a:config.get("mappings.create_header_source_edit_vsplit", ""),
    \       "fun": function("s:set_nnoremap_mapping", [":CXXCMakeCreateHeaderSourceEditVSplit "])
    \   },
    \ }

    return l:ret
endfunction

function! s:cxx_cmake.is_project()
    return self.properties["is_project"]
endfunction

function! s:cxx_cmake.get_project_name()
    return self.properties["project_name"]
endfunction

function! s:cxx_cmake.get_properties()
    return self.properties
endfunction

function! s:cxx_cmake.get_settings_name()
    return "cxx-cmake"
endfunction

function! s:cxx_cmake.enable() abort
    let l:temporary_directory           = self.properties["temporary_directory"]
    let l:build_directory               = self.properties["build_directory"]
    let l:jobs_number                   = self.properties["jobs_number"]
    let l:project_name                  = self.properties["project_name"]
    let l:temporary_ctags_file          = self.properties["temporary_ctags_file"]
    let l:additional_ctags_directories  = self.properties["additional_ctags_directories"]
    let l:external_ctags_files          = self.properties["external_ctags_files"]
    let l:temporary_cscope_file         = self.properties["temporary_cscope_file"]
    let l:additional_cscope_directories = self.properties["additional_cscope_directories"]
    let l:external_cscope_files         = self.properties["external_cscope_files"]
    let l:additional_search_directories = self.properties["additional_search_directories"]
    let l:mappings                      = self.properties["mappings"]
    let l:header_extension              = self.properties["header_extension"]
    let l:source_extension              = self.properties["source_extension"]

    let s:options_initial_values = {
        \ "makeprg":    &makeprg,
        \ "tags":       &tags,
        \ "path":       &path,
    \ }

    call delete(l:temporary_directory, "rf")
    call mkdir(l:temporary_directory)

    call s:set_makeprg(l:build_directory, l:jobs_number)
    call s:add_commands(l:build_directory,
                \ l:project_name,
                \ l:additional_ctags_directories,
                \ l:temporary_ctags_file,
                \ l:additional_cscope_directories,
                \ l:temporary_cscope_file,
                \ l:external_cscope_files,
                \ l:header_extension,
                \ l:source_extension)
    call s:add_mappings(l:mappings)

    let &tags = proset#utils#ctags#get_tags_filenames(l:temporary_ctags_file, l:external_ctags_files)
    call s:generate_tags_file(l:additional_ctags_directories, l:build_directory, l:temporary_ctags_file)
    call s:generate_cscope_file(l:additional_cscope_directories, l:temporary_cscope_file)
    call proset#utils#cscope#add_cscope_files(l:temporary_cscope_file, l:external_cscope_files)
    let &path .= substitute(l:additional_search_directories, ";", ",", "g")
endfunction

function! s:cxx_cmake.disable()
    let &path       = s:options_initial_values["path"]
    let &tags       = s:options_initial_values["tags"]
    let &makeprg    = s:options_initial_values["makeprg"]

    call proset#utils#cscope#remove_all_connections()
    call s:remove_mappings(self.properties["mappings"])
    call s:remove_commands()

    call delete(self.properties["temporary_directory"], "rf")
endfunction

autocmd User ProsetRegisterInternalSettingsEvent
        \ call ProsetRegisterSettings(
        \ s:cxx_cmake.construct(ProsetGetConfiguration()))

function! CXXCMakeConstructor(config)
    return s:cxx_cmake.construct(a:config)
endfunction
