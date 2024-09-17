if exists("g:autoloaded_proset_settings_cxx_cmake_run")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_run = 1

function! s:add_run_command(bin_directory, project_name)
    function! s:run_command_impl(arg) closure
        let l:cmd = a:bin_directory . "/" . a:project_name . " " . a:arg
        call term_start(l:cmd)
    endfunction

    command! -nargs=* CXXCMakeRun call s:run_command_impl(<q-args>)
endfunction

function! s:add_commands(bin_directory, project_name)
    call s:add_run_command(a:bin_directory, a:project_name)
endfunction

function! s:remove_commands()
    delcommand CXXCMakeRun
endfunction

function! s:add_mappings(mappings)
    call proset#lib#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#lib#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_run_properties(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.mappings.run =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "run",
    \       "mappings",
    \       "run"
    \   ),
    \   "function":
    \   function("proset#lib#mapping#set_nnoremap_silent_mapping",
    \       [":CXXCMakeRun<CR>"]
    \   )
    \ }

    let l:ret.mappings.run_args =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "run",
    \       "mappings",
    \       "run_args"
    \   ),
    \   "function":
    \   function("proset#lib#mapping#set_nnoremap_mapping",
    \       [":CXXCMakeRun "]
    \   )
    \ }

    return l:ret
endfunction

let s:object = {'properties': {}, 'input': {}}

function! s:object.construct(config, bin_directory, project_name)
    let l:ret               = deepcopy(self)
    let l:ret.properties    = s:get_run_properties(a:config)

    let l:ret.input =
    \ {
    \   'bin_directory':    a:bin_directory,
    \   'project_name':     a:project_name
    \ }

    return l:ret
endfunction

function! s:object.get_properties()
    return self.properties
endfunction

function! s:object.enable()
    call s:add_commands(self.input.bin_directory, self.input.project_name)
    call s:add_mappings(self.properties.mappings)
endfunction

function! s:object.disable()
    call s:remove_commands()
    call s:remove_mappings(self.properties.mappings)
endfunction

function! proset#settings#cxx_cmake#run#construct(config,
    \       bin_directory,
    \       project_name)
    return s:object.construct(a:config,
    \       a:bin_directory,
    \       a:project_name)
endfunction
