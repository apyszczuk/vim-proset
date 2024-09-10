if exists("g:autoloaded_proset_settings_cxx_cmake_cscope")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_cscope = 1

function! s:generate_cscope_file(source_directory,
    \       additional_cscope_directories,
    \       temporary_cscope_file)
    let l:cmd = proset#utils#cscope#get_cscope_command(a:source_directory,
    \               a:additional_cscope_directories,
    \               a:temporary_cscope_file)
    silent execute "!" . l:cmd
endfunction

function! s:remove_cscope_file(temporary_cscope_file)
    call delete(a:temporary_cscope_file)
endfunction

function! s:connect_cscope_files(temporary_cscope_file,
    \       external_cscope_files)
    call proset#utils#cscope#add_cscope_files(a:temporary_cscope_file,
    \       a:external_cscope_files)
endfunction

function! s:disconnect_cscope_files()
    call proset#utils#cscope#remove_all_connections()
endfunction

function! s:set_cscope_mapping(cmd, seq)
    execute "nnoremap <silent> " . a:seq
    \       . " :cs find " . a:cmd . ' <C-R>=expand("<cword>")<CR><CR>'
endfunction

function! s:add_update_cscope_symbols_command(source_directory,
    \       additional_cscope_directories,
    \       temporary_cscope_file,
    \       external_cscope_files)
    function! s:update_cscope_symbols_command_impl(redraw) closure
        call s:generate_cscope_file(a:source_directory,
        \       a:additional_cscope_directories,
        \       a:temporary_cscope_file)

        call s:connect_cscope_files(a:temporary_cscope_file,
        \       a:external_cscope_files)

        if empty(a:redraw)
            :redraw!
        endif
    endfunction

    command! -nargs=? CXXCMakeUpdateCscopeSymbols
    \   call s:update_cscope_symbols_command_impl(<q-args>)
endfunction

function! s:add_commands(source_directory,
    \       additional_cscope_directories,
    \       temporary_cscope_file,
    \       external_cscope_files)
    call s:add_update_cscope_symbols_command(a:source_directory,
    \       a:additional_cscope_directories,
    \       a:temporary_cscope_file,
    \       a:external_cscope_files)
endfunction

function! s:remove_commands()
    delcommand CXXCMakeUpdateCscopeSymbols
endfunction

function! s:add_mappings(mappings)
    call proset#utils#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#utils#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_cscope_configuration(config)
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
    \   function("proset#utils#mapping#set_nnoremap_silent_mapping",
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

let s:object = {'properties': {}, 'input': {}}

function! s:object.construct(config, temporary_cscope_file, source_directory)
    let l:ret               = deepcopy(self)
    let l:ret.properties    = s:get_cscope_configuration(a:config)

    let l:ret.input =
    \ {
    \   "temporary_cscope_file":    a:temporary_cscope_file,
    \   "source_directory":         a:source_directory
    \ }

    return l:ret
endfunction

function! s:object.get_configuration()
    return self.properties
endfunction

function! s:object.enable()
    call s:generate_cscope_file(self.input.source_directory,
    \       self.properties.settings.additional_cscope_directories,
    \       self.input.temporary_cscope_file)

    call s:connect_cscope_files(self.input.temporary_cscope_file,
    \       self.properties.settings.external_cscope_files)

    call s:add_commands(self.input.source_directory,
    \       self.properties.settings.additional_cscope_directories,
    \       self.input.temporary_cscope_file,
    \       self.properties.settings.external_cscope_files)

    call s:add_mappings(self.properties.mappings)
endfunction

function! s:object.disable()
    call s:disconnect_cscope_files()
    call s:remove_cscope_file(self.input.temporary_cscope_file)
    call s:remove_commands()
    call s:remove_mappings(self.properties.mappings)
endfunction

function! proset#settings#cxx_cmake#cscope#construct(config,
    \       temporary_cscope_file,
    \       source_directory)
    return s:object.construct(a:config,
    \       a:temporary_cscope_file,
    \       a:source_directory)
endfunction
