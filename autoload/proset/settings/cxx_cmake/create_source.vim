if exists("g:autoloaded_proset_settings_cxx_cmake_create_source")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_create_source = 1

function! proset#settings#cxx_cmake#create_source#create_source_file(
    \       project_name,
    \       path,
    \       header_extension)
    let l:header_path = fnamemodify(a:path, ":t:r") . "." . a:header_extension
    let l:file_content = "#include \"" . l:header_path . "\"\n"
    if writefile(split(l:file_content, "\n"), a:path) == -1
        return ""
    endif
    return a:path
endfunction

function! proset#settings#cxx_cmake#create_source#create_source_command(
    \       open_mode,
    \       input,
    \       path)
    return proset#settings#cxx_cmake#create_header#create_file_command(
    \       "proset#settings#cxx_cmake#create_source#create_source_file",
    \       "CXXCMakeSourceCreatedEvent",
    \       a:open_mode,
    \       a:input.project_name,
    \       a:input.source_extension,
    \       a:input.header_extension,
    \       a:path)
endfunction

function! s:add_create_source_command(input_dict)
    function! s:create_source_command_impl(path) closure
        call proset#settings#cxx_cmake#create_source#create_source_command(
        \       "",
        \       a:input_dict,
        \       a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateSource
    \   call s:create_source_command_impl(<f-args>)
endfunction

function! s:add_create_source_edit_command(input_dict)
    function! s:create_source_edit_command_impl(path) closure
        call proset#settings#cxx_cmake#create_source#create_source_command(
        \       ":e",
        \       a:input_dict,
        \       a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateSourceEdit
    \   call s:create_source_edit_command_impl(<f-args>)
endfunction

function! s:add_create_source_edit_split_command(input_dict)
    function! s:create_source_edit_split_command_impl(path) closure
        call proset#settings#cxx_cmake#create_source#create_source_command(
        \       ":spl",
        \       a:input_dict,
        \       a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateSourceEditSplit
    \   call s:create_source_edit_split_command_impl(<f-args>)
endfunction

function! s:add_create_source_edit_vsplit_command(input_dict)
    function! s:create_source_edit_vsplit_command_impl(path) closure
        call proset#settings#cxx_cmake#create_source#create_source_command(
        \       ":vspl",
        \       a:input_dict,
        \       a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateSourceEditVSplit
    \   call s:create_source_edit_vsplit_command_impl(<f-args>)
endfunction

function! s:add_commands(input_dict)
    call s:add_create_source_command(a:input_dict)
    call s:add_create_source_edit_command(a:input_dict)
    call s:add_create_source_edit_split_command(a:input_dict)
    call s:add_create_source_edit_vsplit_command(a:input_dict)
endfunction

function! s:remove_commands()
    delcommand CXXCMakeCreateSource
    delcommand CXXCMakeCreateSourceEdit
    delcommand CXXCMakeCreateSourceEditSplit
    delcommand CXXCMakeCreateSourceEditVSplit
endfunction

function! s:add_mappings(mappings)
    call proset#lib#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#lib#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_create_source_properties(config)
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
    \   function("proset#lib#mapping#set_nnoremap_mapping",
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
    \   function("proset#lib#mapping#set_nnoremap_mapping",
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
    \   function("proset#lib#mapping#set_nnoremap_mapping",
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
    \   function("proset#lib#mapping#set_nnoremap_mapping",
    \       [":CXXCMakeCreateSourceEditVSplit "]
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

function! proset#settings#cxx_cmake#create_source#construct(config,
    \       project_name,
    \       header_extension,
    \       source_extension)
    let l:ret               = deepcopy(s:object)
    let l:ret.properties    = s:get_create_source_properties(a:config)
    let l:ret.input         =
    \ {
    \   "project_name":     a:project_name,
    \   "header_extension": a:header_extension,
    \   "source_extension": a:source_extension
    \ }

    return l:ret
endfunction
