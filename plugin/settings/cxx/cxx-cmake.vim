" cxx-cmake - CXX CMake Settings Dictionary
"
" Author:     Artur Pyszczuk <apyszczuk@gmail.com>
" License:    Same terms as Vim itself
" Website:    https://github.com/apyszczuk/vim-proset

if exists("g:loaded_proset_settings_cxx_cxx_cmake")
    finish
endif
let g:loaded_proset_settings_cxx_cxx_cmake = 1

let s:cxx_cmake = {'properties': {}, 'modules': {}}

function! s:get_top_level_properties(config)
    let l:ret = {}

    let l:ret.proset_settings =
    \ proset#lib#dict#get(a:config,
    \   "",
    \   "proset_settings"
    \ )

    let l:ret.temporary_directory =
    \ proset#utils#path#get_correct_path(a:config,
    \   ".vim-proset_tmp",
    \   "temporary_directory"
    \ )

    return l:ret
endfunction

function! s:cxx_cmake.construct(config)
    let l:ret = deepcopy(self)

    let l:ret.properties =
    \ extend(l:ret.properties, s:get_top_level_properties(a:config))

    let l:ret.modules.build =
    \ proset#settings#cxx_cmake#build#construct(a:config)
    let l:ret.properties.build =
    \ l:ret.modules.build.get_properties()

    let l:ret.modules.source =
    \ proset#settings#cxx_cmake#source#construct(a:config)
    let l:ret.properties.source =
    \ l:ret.modules.source.get_properties()

    let l:ret.modules.cmake =
    \ proset#settings#cxx_cmake#cmake#construct(a:config,
    \   l:ret.properties.build.settings.build_directory,
    \   l:ret.properties.source.settings.source_directory,
    \   g:proset_settings_file)
    let l:ret.properties.cmake =
    \ l:ret.modules.cmake.get_properties()

    let l:ret.modules.ctags =
    \ proset#settings#cxx_cmake#ctags#construct(a:config,
    \       l:ret.properties.source.settings.source_directory,
    \       l:ret.properties.temporary_directory)
    let l:ret.properties.ctags =
    \ l:ret.modules.ctags.get_properties()

    let l:ret.modules.cscope =
    \ proset#settings#cxx_cmake#cscope#construct(a:config,
    \       l:ret.properties.source.settings.source_directory,
    \       l:ret.properties.temporary_directory)
    let l:ret.properties.cscope =
    \ l:ret.modules.cscope.get_properties()

    let l:ret.modules.run =
    \ proset#settings#cxx_cmake#run#construct(a:config,
    \       l:ret.properties.cmake.settings.bin_directory,
    \       l:ret.properties.cmake.settings.project_name)
    let l:ret.properties.run =
    \ l:ret.modules.run.get_properties()

    let l:ret.modules.symbols =
    \ proset#settings#cxx_cmake#symbols#construct(a:config)
    let l:ret.properties.symbols =
    \ l:ret.modules.symbols.get_properties()

    let l:ret.modules.alternate_file =
    \ proset#settings#cxx_cmake#alternate_file#construct(a:config,
    \       l:ret.properties.source.settings.header_extension,
    \       l:ret.properties.source.settings.source_extension)
    let l:ret.properties.alternate_file =
    \ l:ret.modules.alternate_file.get_properties()

    let l:ret.modules.create_header =
    \ proset#settings#cxx_cmake#create_header#construct(a:config,
    \       l:ret.properties.cmake.settings.project_name,
    \       l:ret.properties.source.settings.header_extension,
    \       l:ret.properties.source.settings.source_extension)
    let l:ret.properties.create_header =
    \ l:ret.modules.create_header.get_properties()

    let l:ret.modules.create_source =
    \ proset#settings#cxx_cmake#create_source#construct(a:config,
    \       l:ret.properties.cmake.settings.project_name,
    \       l:ret.properties.source.settings.header_extension,
    \       l:ret.properties.source.settings.source_extension)
    let l:ret.properties.create_source =
    \ l:ret.modules.create_source.get_properties()

    let l:ret.modules.create_header_source =
    \ proset#settings#cxx_cmake#create_header_source#construct(a:config,
    \       l:ret.properties.cmake.settings.project_name,
    \       l:ret.properties.source.settings.header_extension,
    \       l:ret.properties.source.settings.source_extension)
    let l:ret.properties.create_header_source =
    \ l:ret.modules.create_header_source.get_properties()

    return l:ret
endfunction

function! s:cxx_cmake.is_project()
    return self.properties.cmake.settings.is_project
endfunction

function! s:cxx_cmake.get_project_name()
    return self.properties.cmake.settings.project_name
endfunction

function! s:cxx_cmake.get_properties()
    return self.properties
endfunction

function! s:cxx_cmake.get_settings_name()
    return "cxx-cmake"
endfunction

function! s:cxx_cmake.enable() abort
    let l:tempdir = self.properties.temporary_directory

    call delete(l:tempdir, "rf")
    call mkdir(l:tempdir, "p")

    call s:enable_modules(self.modules)
endfunction

function! s:cxx_cmake.disable()
    call s:disable_modules(self.modules)

    call delete(self.properties.temporary_directory, "rf")
endfunction

function! s:enable_modules(modules)
    for i in keys(a:modules)
        call a:modules[i].enable()
    endfor
endfunction

function! s:disable_modules(modules)
    for i in keys(a:modules)
        call a:modules[i].disable()
    endfor
endfunction

autocmd User ProsetRegisterInternalSettingsEvent
    \ call ProsetRegisterSettings("cxx-cmake", "CXXCMakeConstruct")

function! CXXCMakeConstruct(config)
    return s:cxx_cmake.construct(a:config)
endfunction
