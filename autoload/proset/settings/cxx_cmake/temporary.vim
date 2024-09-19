if exists("g:autoloaded_proset_settings_cxx_cmake_temporary")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_temporary = 1

function! s:get_temporary_properties(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.temporary_directory =
    \ proset#lib#path#get_subpath(a:config,
    \   ".vim-proset_tmp",
    \   "temporary",
    \   "settings",
    \   "temporary_directory"
    \ )

    return l:ret
endfunction

let s:object = {"properties": {}}

function! s:object.get_properties()
    return self.properties
endfunction

function! s:object.enable()
endfunction

function! s:object.disable()
endfunction

function! proset#settings#cxx_cmake#temporary#construct(config)
    let l:ret               = deepcopy(s:object)
    let l:ret.properties    = s:get_temporary_properties(a:config)

    return l:ret
endfunction
