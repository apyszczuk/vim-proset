if exists("g:autoloaded_proset_settings_cxx_cmake_ctags")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_ctags = 1

function! s:generate_ctags_file(source_directory,
    \       additional_ctags_directories,
    \       temporary_ctags_file)
    let l:cmd = proset#utils#ctags#get_ctags_command(a:source_directory,
    \               a:additional_ctags_directories,
    \               a:temporary_ctags_file)
    silent execute '!' . l:cmd
endfunction

function! s:remove_ctags_file(temporary_ctags_file)
    call delete(a:temporary_ctags_file)
endfunction

function! s:set_tags_option(temporary_ctags_file, external_ctags_files)
    let s:init_tags = &tags
    let &tags = proset#utils#ctags#get_ctags_filenames(a:temporary_ctags_file,
    \               a:external_ctags_files)
endfunction

function! s:restore_tags_option()
    let &tags = s:init_tags
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

function! s:add_commands(source_directory,
    \       additional_ctags_directories,
    \       temporary_ctags_file)
    call s:add_update_ctags_symbols_command(a:source_directory,
    \       a:additional_ctags_directories,
    \       a:temporary_ctags_file)
endfunction

function! s:remove_commands()
    delcommand CXXCMakeUpdateCtagsSymbols
endfunction

function! s:add_mappings(mappings)
    call proset#utils#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#utils#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_ctags_configuration(config)
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
    \   function("proset#utils#mapping#set_nnoremap_silent_mapping",
    \       [":CXXCMakeUpdateCtagsSymbols<CR>"]
    \   )
    \ }

    return l:ret
endfunction

let s:object = {'properties': {}, 'input': {}}

function! s:object.construct(config, temporary_ctags_file, source_directory)
    let l:ret               = deepcopy(self)
    let l:ret.properties    = s:get_ctags_configuration(a:config)

    let l:ret.input =
    \ {
    \   "temporary_ctags_file":     a:temporary_ctags_file,
    \   "source_directory":         a:source_directory
    \ }

    return l:ret
endfunction

function! s:object.get_configuration()
    return self.properties
endfunction

function! s:object.enable()
    call s:set_tags_option(self.input.temporary_ctags_file,
    \       self.properties.settings.external_ctags_files)

    call s:generate_ctags_file(self.input.source_directory,
    \       self.properties.settings.additional_ctags_directories,
    \       self.input.temporary_ctags_file)

    call s:add_commands(self.input.source_directory,
    \       self.properties.settings.additional_ctags_directories,
    \       self.input.temporary_ctags_file)

    call s:add_mappings(self.properties.mappings)
endfunction

function! s:object.disable()
    call s:restore_tags_option()
    call s:remove_ctags_file(self.input.temporary_ctags_file)
    call s:remove_commands()
    call s:remove_mappings(self.properties.mappings)
endfunction

function! proset#settings#cxx_cmake#ctags#construct(config,
    \       temporary_ctags_file,
    \       source_directory)
    return s:object.construct(a:config,
    \       a:temporary_ctags_file,
    \       a:source_directory)
endfunction
