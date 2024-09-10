if exists("g:autoloaded_proset_settings_cxx_cmake_alternate_file")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_alternate_file = 1

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

function! s:add_extensions_pair(header_extension, source_extension)
    call proset#utils#alternate_file#add_extensions_pair(a:header_extension,
    \       a:source_extension)
endfunction

function! s:remove_extensions_pair(header_extension)
    call proset#utils#alternate_file#remove_extensions_pair(a:header_extension)
endfunction

function! s:add_commands()
    call s:add_alternate_file_current_window_command()
    call s:add_alternate_file_split_window_command()
    call s:add_alternate_file_vsplit_window_command()
endfunction

function! s:remove_commands()
    delcommand CXXCMakeAlternateFileCurrentWindow
    delcommand CXXCMakeAlternateFileSplitWindow
    delcommand CXXCMakeAlternateFileVSplitWindow
endfunction

function! s:add_mappings(mappings)
    call proset#utils#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#utils#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_alternate_file_configuration(config)
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
    \   function("proset#utils#mapping#set_nnoremap_silent_mapping",
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
    \   function("proset#utils#mapping#set_nnoremap_silent_mapping",
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
    \   function("proset#utils#mapping#set_nnoremap_silent_mapping",
    \       [":CXXCMakeAlternateFileVSplitWindow<CR>"]
    \   )
    \ }

    return l:ret
endfunction

let s:object = {'properties': {}, 'input': {}}

function! s:object.construct(config, header_extension, source_extension)
    let l:ret               = deepcopy(self)
    let l:ret.properties    = s:get_alternate_file_configuration(a:config)

    let l:ret.input =
    \ {
    \   'header_extension':     a:header_extension,
    \   'source_extension':     a:source_extension
    \ }

    return l:ret
endfunction

function! s:object.get_configuration()
    return self.properties
endfunction

function! s:object.enable()
    call s:add_commands()
    call s:add_mappings(self.properties.mappings)
    call s:add_extensions_pair(self.input.header_extension,
    \       self.input.source_extension)
endfunction

function! s:object.disable()
    call s:remove_commands()
    call s:remove_mappings(self.properties.mappings)
    call s:remove_extensions_pair(self.input.header_extension)
endfunction

function! proset#settings#cxx_cmake#alternate_file#construct(config,
    \       header_extension,
    \       source_extension)
    return s:object.construct(a:config,
    \       a:header_extension,
    \       a:source_extension)
endfunction
