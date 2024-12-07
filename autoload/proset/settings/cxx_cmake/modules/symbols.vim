if exists("g:autoloaded_proset_settings_cxx_cmake_modules_symbols")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_modules_symbols = 1

function! s:add_update_symbols_command()
    function! s:update_symbols_command_impl()
        :CXXCMakeUpdateCtagsSymbols 0
        :CXXCMakeUpdateCscopeSymbols 0
        :redraw!
    endfunction

    command! -nargs=0 CXXCMakeUpdateSymbols call s:update_symbols_command_impl()
endfunction

function! s:add_commands()
    call s:add_update_symbols_command()
endfunction

function! s:remove_commands()
    delcommand CXXCMakeUpdateSymbols
endfunction

function! s:add_mappings(mappings)
    call proset#lib#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#lib#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_symbols_properties(config)
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
    \   function("proset#lib#mapping#set_nnoremap_silent_mapping",
    \       [":CXXCMakeUpdateSymbols<CR>"]
    \   )
    \ }

    return l:ret
endfunction

let s:object = {"properties": {}}

function! s:object.get_properties()
    return self.properties
endfunction

function! s:object.enable()
    call s:add_commands()
    call s:add_mappings(self.properties.mappings)
endfunction

function! s:object.disable()
    call s:remove_commands()
    call s:remove_mappings(self.properties.mappings)
endfunction

function! s:object.get_module_properties()
    let l:ret           = {}
    let l:ret.settings  = self.properties.settings
    let l:ret.mappings
    \ = proset#settings#cxx_cmake#create#convert_mappings(self.properties.mappings)

    return l:ret
endfunction

function! proset#settings#cxx_cmake#modules#symbols#construct(config)
    let l:ret               = deepcopy(s:object)
    let l:ret.properties    = s:get_symbols_properties(a:config)

    return l:ret
endfunction
