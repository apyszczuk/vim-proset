if exists("g:autoloaded_proset_settings_cxx_cmake_create_header")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_create_header = 1

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

function! proset#settings#cxx_cmake#create_header#create_file_command(
    \       create_function,
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

function! proset#settings#cxx_cmake#create_header#create_header_command(
    \       open_mode,
    \       input,
    \       path)
    return proset#settings#cxx_cmake#create_header#create_file_command(
    \       "s:create_header_file",
    \       "CXXCMakeHeaderCreatedEvent",
    \       a:open_mode,
    \       a:input.project_name,
    \       a:input.header_extension,
    \       a:input.source_extension,
    \       a:path)
endfunction

function! s:add_create_header_command(input_dict)
    function! s:create_header_command_impl(path) closure
        call proset#settings#cxx_cmake#create_header#create_header_command(
        \       "",
        \       a:input_dict,
        \       a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeader
    \   call s:create_header_command_impl(<f-args>)
endfunction

function! s:add_create_header_edit_command(input_dict)
    function! s:create_header_edit_command_impl(path) closure
        call proset#settings#cxx_cmake#create_header#create_header_command(
        \       ":e",
        \       a:input_dict,
        \       a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderEdit
    \   call s:create_header_edit_command_impl(<f-args>)
endfunction

function! s:add_create_header_edit_split_command(input_dict)
    function! s:create_header_edit_split_command_impl(path) closure
        call proset#settings#cxx_cmake#create_header#create_header_command(
        \       ":spl",
        \       a:input_dict,
        \       a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderEditSplit
    \   call s:create_header_edit_split_command_impl(<f-args>)
endfunction

function! s:add_create_header_edit_vsplit_command(input_dict)
    function! s:create_header_edit_vsplit_command_impl(path) closure
        call proset#settings#cxx_cmake#create_header#create_header_command(
        \       ":vspl",
        \       a:input_dict,
        \       a:path)
    endfunction

    command! -complete=file -nargs=1 CXXCMakeCreateHeaderEditVSplit
    \   call s:create_header_edit_vsplit_command_impl(<f-args>)
endfunction

function! s:add_commands(input_dict)
    call s:add_create_header_command(a:input_dict)
    call s:add_create_header_edit_command(a:input_dict)
    call s:add_create_header_edit_split_command(a:input_dict)
    call s:add_create_header_edit_vsplit_command(a:input_dict)
endfunction

function! s:remove_commands()
    delcommand CXXCMakeCreateHeader
    delcommand CXXCMakeCreateHeaderEdit
    delcommand CXXCMakeCreateHeaderEditSplit
    delcommand CXXCMakeCreateHeaderEditVSplit
endfunction

function! s:add_mappings(mappings)
    call proset#utils#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#utils#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_create_header_properties(config)
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
    \   function("proset#utils#mapping#set_nnoremap_mapping",
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
    \   function("proset#utils#mapping#set_nnoremap_mapping",
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
    \   function("proset#utils#mapping#set_nnoremap_mapping",
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
    \   function("proset#utils#mapping#set_nnoremap_mapping",
    \       [":CXXCMakeCreateHeaderEditVSplit "]
    \   )
    \ }

    return l:ret
endfunction

let s:object = {'properties': {}, 'input': {}}

function! s:object.construct(config,
    \       project_name,
    \       header_extension,
    \       source_extension)
    let l:ret               = deepcopy(self)
    let l:ret.properties    = s:get_create_header_properties(a:config)

    let l:ret.input =
    \ {
    \   'project_name':     a:project_name,
    \   'header_extension': a:header_extension,
    \   'source_extension': a:source_extension
    \ }

    return l:ret
endfunction

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

function! proset#settings#cxx_cmake#create_header#construct(config,
    \       project_name,
    \       header_extension,
    \       source_extension)
    return s:object.construct(a:config,
    \       a:project_name,
    \       a:header_extension,
    \       a:source_extension)
endfunction
