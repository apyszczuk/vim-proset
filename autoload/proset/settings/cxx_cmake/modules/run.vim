if exists("g:autoloaded_proset_settings_cxx_cmake_modules_run")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_modules_run = 1

let s:buf_nr        = -1
let s:buf_nr_prev   = -1

function! s:add_run_command(bin_directory, project_name)
    function! s:exit_callback(job, status)
        if bufexists(s:buf_nr_prev)
            execute ":bd " . s:buf_nr_prev
        endif
    endfunction

    function! s:run_command_impl(new_window, arg) closure
        if a:new_window == 1
            let s:buf_nr        = -1
            let s:buf_nr_prev   = -1
        endif

        let l:cmd = a:bin_directory . "/" . a:project_name . " " . a:arg

        let l:opts = {"exit_cb": "s:exit_callback"}

        let l:winid = bufwinid(s:buf_nr)
        if l:winid != -1
            call win_gotoid(l:winid)
            let l:opts["curwin"] = 1
        endif

        if s:buf_nr > 0
            let s:buf_nr_prev = s:buf_nr
        endif
        
        let s:buf_nr = term_start(l:cmd, l:opts)
    endfunction

    command! -nargs=* CXXCMakeRun           call s:run_command_impl(0, <q-args>)
    command! -nargs=* CXXCMakeRunNewWindow  call s:run_command_impl(1, <q-args>)
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

    let l:ret.mappings.run_new_window =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "run",
    \       "mappings",
    \       "run_new_window"
    \   ),
    \   "function":
    \   function("proset#lib#mapping#set_nnoremap_silent_mapping",
    \       [":CXXCMakeRunNewWindow<CR>"]
    \   )
    \ }

    let l:ret.mappings.run_args_new_window =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "run",
    \       "mappings",
    \       "run_args_new_window"
    \   ),
    \   "function":
    \   function("proset#lib#mapping#set_nnoremap_mapping",
    \       [":CXXCMakeRunNewWindow "]
    \   )
    \ }

    return l:ret
endfunction

let s:object = {"properties": {}, "input": {}}

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

function! s:object.get_module_properties()
    let l:ret           = {}
    let l:ret.settings  = self.properties.settings
    let l:ret.mappings
    \ = proset#settings#cxx_cmake#create#convert_mappings(self.properties.mappings)

    return l:ret
endfunction

function! proset#settings#cxx_cmake#modules#run#construct(config,
\           bin_directory,
\           project_name)
    let l:ret               = deepcopy(s:object)
    let l:ret.properties    = s:get_run_properties(a:config)
    let l:ret.input         =
    \ {
    \   "bin_directory":    a:bin_directory,
    \   "project_name":     a:project_name
    \ }

    return l:ret
endfunction
