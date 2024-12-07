if exists("g:autoloaded_proset_settings_cxx_cmake_modules_ctags")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_modules_ctags = 1

function! s:get_ctags_command(source_directory,
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

function! s:get_ctags_filenames(temporary_ctags_file,
        \ external_ctags_files)
    let l:ret   = a:temporary_ctags_file
    let l:files = substitute(a:external_ctags_files, ";", ",", "g")
    if !empty(l:files)
        let l:ret .= "," . l:files
    endif
    return l:ret
endfunction

function! s:generate_ctags_file(source_directory,
    \       additional_ctags_directories,
    \       temporary_ctags_file)
    let l:cmd = s:get_ctags_command(a:source_directory,
    \               a:additional_ctags_directories,
    \               a:temporary_ctags_file)
    silent execute '!' . l:cmd
endfunction

function! s:remove_ctags_file(temporary_ctags_file)
    call delete(a:temporary_ctags_file)
endfunction

function! s:set_tags_option(temporary_ctags_file, external_ctags_files)
    let s:init_tags = &tags
    let &tags = s:get_ctags_filenames(a:temporary_ctags_file,
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
    call proset#lib#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#lib#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_ctags_properties(config, temporary_directory)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.temporary_ctags_file = a:temporary_directory . "/ctags"

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
    \   function("proset#lib#mapping#set_nnoremap_silent_mapping",
    \       [":CXXCMakeUpdateCtagsSymbols<CR>"]
    \   )
    \ }

    return l:ret
endfunction

let s:object = {"properties": {}, "input": {}}

function! s:object.get_properties()
    return self.properties
endfunction

function! s:object.enable()
    call s:set_tags_option(self.properties.settings.temporary_ctags_file,
    \       self.properties.settings.external_ctags_files)

    call s:generate_ctags_file(self.input.source_directory,
    \       self.properties.settings.additional_ctags_directories,
    \       self.properties.settings.temporary_ctags_file)

    call s:add_commands(self.input.source_directory,
    \       self.properties.settings.additional_ctags_directories,
    \       self.properties.settings.temporary_ctags_file)

    call s:add_mappings(self.properties.mappings)
endfunction

function! s:object.disable()
    call s:restore_tags_option()
    call s:remove_ctags_file(self.properties.settings.temporary_ctags_file)
    call s:remove_commands()
    call s:remove_mappings(self.properties.mappings)
endfunction

function! s:object.get_module_properties()
    let l:ret           = {}
    let l:ret.settings  = self.properties.settings
    let l:ret.mappings
    \ = proset#settings#cxx_cmake#create#convert_mappings(self.properties.mappings)

    call proset#lib#dict#remove_if_exists(l:ret.settings, "temporary_ctags_file")

    let l:ret.settings.additional_ctags_directories
    \ = split(l:ret.settings.additional_ctags_directories, ";")
    let l:ret.settings.external_ctags_files
    \ = split(l:ret.settings.external_ctags_files, ";")

    return l:ret
endfunction

function! proset#settings#cxx_cmake#modules#ctags#construct(config,
    \       source_directory,
    \       temporary_directory)
    let l:ret               = deepcopy(s:object)
    let l:ret.properties    = s:get_ctags_properties(a:config,
    \                           a:temporary_directory)
    let l:ret.input         =
    \ {
    \   "source_directory": a:source_directory
    \ }

    return l:ret
endfunction
