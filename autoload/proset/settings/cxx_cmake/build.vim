if exists("g:autoloaded_proset_settings_cxx_cmake_build")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_build = 1

function! s:add_build_command()
    function! s:post_build_task()
        let l:msg = "Success: "
        let l:st  = 0

        if g:asyncrun_code != 0
            let l:msg = "Failure: "
            let l:st  = 1
        else
            let l:list = getqflist()
            for item in l:list
                if item["valid"] == 1
                    let l:st = 1
                    break
                endif
            endfor
        endif

        echo l:msg . &makeprg
        if l:st == 0
            :ccl
        endif
    endfunction

    function! s:build_command_impl()
        :update
        :AsyncRun -program=make -post=call\ <SID>post_build_task()
    endfunction

    command! -nargs=0 CXXCMakeBuild call s:build_command_impl()
endfunction

function! s:add_clean_command(build_directory)
    function! s:clean_command_impl() closure
        call delete(a:build_directory, "rf")
    endfunction

    command! -nargs=0 CXXCMakeClean call s:clean_command_impl()
endfunction

function! s:add_clean_and_build_command()
    function! s:clean_and_build_command_impl()
        :CXXCMakeClean
        :CXXCMakeBuild
    endfunction

    command -nargs=0 CXXCMakeCleanAndBuild call s:clean_and_build_command_impl()
endfunction

function! s:get_build_command(build_directory, jobs_number)
    let l:cmd = "cmake " .
                \ "-B" . a:build_directory . " . " .
                \ "&& " .
                \ "cmake " .
                \ "--build " . a:build_directory . " -- -j" . a:jobs_number
    return l:cmd
endfunction

function! s:set_makeprg_option(build_directory, jobs_number)
    let s:init_makeprg  = &makeprg
    let &makeprg        = s:get_build_command(a:build_directory, a:jobs_number)
endfunction

function! s:restore_makeprg_option()
    let &makeprg = s:init_makeprg
endfunction

function! s:add_commands(build_directory)
    call s:add_build_command()
    call s:add_clean_command(a:build_directory)
    call s:add_clean_and_build_command()
endfunction

function! s:remove_commands()
    delcommand CXXCMakeBuild
    delcommand CXXCMakeClean
    delcommand CXXCMakeCleanAndBuild
endfunction

function! s:add_mappings(mappings)
    call proset#lib#mapping#add_mappings(a:mappings)
endfunction

function! s:remove_mappings(mappings)
    call proset#lib#mapping#remove_mappings(a:mappings)
endfunction

function! s:get_build_properties(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.build_directory =
    \ proset#lib#path#get_subpath(a:config,
    \   "build",
    \   "build",
    \   "settings",
    \   "build_directory"
    \ )

    let l:ret.settings.jobs =
    \ proset#lib#dict#get(a:config,
    \   "1",
    \   "build",
    \   "settings",
    \   "jobs"
    \ )

    let l:ret.mappings.build =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "build",
    \       "mappings",
    \       "build"
    \   ),
    \   "function":
    \   function("proset#lib#mapping#set_nnoremap_silent_mapping",
    \       [":CXXCMakeBuild<CR>"]
    \   )
    \ }

    let l:ret.mappings.clean =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "build",
    \       "mappings",
    \       "clean"
    \   ),
    \   "function":
    \   function("proset#lib#mapping#set_nnoremap_silent_mapping",
    \       [":CXXCMakeClean<CR>"]
    \   )
    \ }

    let l:ret.mappings.clean_and_build =
    \ {
    \   "sequence":
    \   proset#lib#dict#get(a:config,
    \       "",
    \       "build",
    \       "mappings",
    \       "clean_and_build"
    \   ),
    \   "function":
    \   function("proset#lib#mapping#set_nnoremap_silent_mapping",
    \       [":CXXCMakeCleanAndBuild<CR>"]
    \   )
    \ }

    return l:ret
endfunction

let s:object = {"properties": {}}

function! s:object.get_properties()
    return self.properties
endfunction

function! s:object.enable()
    let l:build_dir = self.properties.settings.build_directory
    call s:set_makeprg_option(l:build_dir, self.properties.settings.jobs)
    call s:add_commands(l:build_dir)
    call s:add_mappings(self.properties.mappings)
endfunction

function! s:object.disable()
    call s:restore_makeprg_option()
    call s:remove_commands()
    call s:remove_mappings(self.properties.mappings)
endfunction

function! proset#settings#cxx_cmake#build#construct(config)
    let l:ret               = deepcopy(s:object)
    let l:ret.properties    = s:get_build_properties(a:config)

    return l:ret
endfunction
