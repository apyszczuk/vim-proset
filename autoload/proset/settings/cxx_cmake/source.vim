if exists("g:autoloaded_proset_settings_cxx_cmake_source")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_source = 1

function! s:set_path_option(additional_search_directories)
    let s:init_path = &path
    let &path .= substitute(a:additional_search_directories, ";", ",", "g")
endfunction

function! s:restore_path_option()
    let &path = s:init_path
endfunction

function! s:get_source_configuration(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.source_directory =
    \ proset#utils#path#get_correct_path(a:config,
    \   "src",
    \   "source",
    \   "settings",
    \   "source_directory"
    \ )

    let l:ret.settings.header_extension =
    \ proset#lib#dict#get_not_empty(a:config,
    \   "hpp",
    \   "source",
    \   "settings",
    \   "header_extension"
    \ )

    let l:ret.settings.source_extension =
    \ proset#lib#dict#get_not_empty(a:config,
    \   "cpp",
    \   "source",
    \   "settings",
    \   "source_extension"
    \ )

    let l:ret.settings.additional_search_directories =
    \ join(
    \   proset#lib#dict#get(a:config,
    \       [],
    \       "source",
    \       "settings",
    \       "additional_search_directories"
    \   ),
    \   ";"
    \ )

    return l:ret
endfunction

let s:object = {'properties': {}}

function! s:object.construct(config)
    let l:ret               = deepcopy(self)
    let l:ret.properties    = s:get_source_configuration(a:config)

    return l:ret
endfunction

function! s:object.get_configuration()
    return self.properties
endfunction

function! s:object.enable()
    call s:set_path_option(self.properties.settings.additional_search_directories)
endfunction

function! s:object.disable()
    call s:restore_path_option()
endfunction

function! proset#settings#cxx_cmake#source#construct(config)
    return s:object.construct(a:config)
endfunction
