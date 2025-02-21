if exists("g:autoloaded_proset_settings_cxx_cmake_modules_source")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_modules_source = 1

function! s:set_path_option(additional_search_directories)
    let s:init_path = &path
    let &path .= substitute(a:additional_search_directories, ";", ",", "g")
endfunction

function! s:restore_path_option()
    let &path = s:init_path
endfunction

function! s:get_source_properties(config)
    let l:ret = {"settings": {}, "mappings": {}}

    let l:ret.settings.source_directory =
    \ proset#lib#path#get_subpath(a:config,
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

let s:object = {"properties": {}}

function! s:object.get_properties()
    return self.properties
endfunction

function! s:object.enable()
    call s:set_path_option(self.properties.settings.additional_search_directories)
endfunction

function! s:object.disable()
    call s:restore_path_option()
endfunction

function! s:object.get_module_properties()
    let l:ret           = {}
    let l:ret.settings  = self.properties.settings
    let l:ret.mappings
    \ = proset#settings#cxx_cmake#create#convert_mappings(self.properties.mappings)

    let l:ret.settings.additional_search_directories
    \ = split(l:ret.settings.additional_search_directories, ";")

    return l:ret
endfunction

function! proset#settings#cxx_cmake#modules#source#construct(config)
    let l:ret               = deepcopy(s:object)
    let l:ret.properties    = s:get_source_properties(a:config)

    return l:ret
endfunction
