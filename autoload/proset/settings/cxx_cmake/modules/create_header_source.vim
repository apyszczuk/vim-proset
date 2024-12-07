if exists("g:autoloaded_proset_settings_cxx_cmake_modules_create_header_source")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_modules_create_header_source = 1

function! s:create_header_source_command(open_mode, input, path)
    let l:open_modes = split(a:open_mode, ";", 1)

    call proset#settings#cxx_cmake#modules#create_header#create_header_command(
    \       l:open_modes[0],
    \       a:input,
    \       a:path)
    call proset#settings#cxx_cmake#modules#create_source#create_source_command(
    \       l:open_modes[1],
    \       a:input,
    \       a:path)
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

function! s:add_commands(input_dict)
    call s:add_create_header_source_command(a:input_dict)
    call s:add_create_header_source_edit_split_command(a:input_dict)
    call s:add_create_header_source_edit_vsplit_command(a:input_dict)
    call s:add_create_header_source_edit_current_split_command(a:input_dict)
    call s:add_create_header_source_edit_current_vsplit_command(a:input_dict)
endfunction

function! s:remove_commands()
    delcommand CXXCMakeCreateHeaderSource
    delcommand CXXCMakeCreateHeaderSourceEditSplit
    delcommand CXXCMakeCreateHeaderSourceEditVSplit
    delcommand CXXCMakeCreateHeaderSourceEditCurrentSplit
    delcommand CXXCMakeCreateHeaderSourceEditCurrentVSplit
endfunction

function! s:add_mappings(mappings)
    call proset#lib#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#lib#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_create_header_source_properties(config)
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
    \   function("proset#lib#mapping#set_nnoremap_mapping",
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
    \   function("proset#lib#mapping#set_nnoremap_mapping",
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
    \   function("proset#lib#mapping#set_nnoremap_mapping",
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
    \   function("proset#lib#mapping#set_nnoremap_mapping",
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
    \   function("proset#lib#mapping#set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderSourceEditCurrentVSplit "]
    \   )
    \ }

    return l:ret
endfunction

let s:object = {"properties": {}, "input": {}}

function! s:object.get_properties()
    return self.properties
endfunction

function! s:object.enable()
    call s:add_commands(self.input)
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

function! proset#settings#cxx_cmake#modules#create_header_source#construct(config,
    \       project_name,
    \       header_extension,
    \       source_extension)
    let l:ret               = deepcopy(s:object)
    let l:ret.properties    = s:get_create_header_source_properties(a:config)
    let l:ret.input         =
    \ {
    \   "project_name":     a:project_name,
    \   "header_extension": a:header_extension,
    \   "source_extension": a:source_extension
    \ }

    return l:ret
endfunction
