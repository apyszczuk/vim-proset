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

function! s:get_top_level_configuration(config)
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

    let l:ret.properties.configuration = {}

    let l:ret.properties.configuration =
    \ extend(l:ret.properties.configuration,
    \   s:get_top_level_configuration(a:config))


    let l:ret.modules.build =
    \ proset#settings#cxx_cmake#build#construct(a:config)
    let l:ret.properties.configuration.build =
    \ l:ret.modules.build.get_configuration()

    let l:ret.modules.source =
    \ proset#settings#cxx_cmake#source#construct(a:config)
    let l:ret.properties.configuration.source =
    \ l:ret.modules.source.get_configuration()

    let l:ret.modules.cmake =
    \ proset#settings#cxx_cmake#cmake#construct(a:config,
    \   l:ret.properties.configuration.build.settings.build_directory)
    let l:ret.properties.configuration.cmake =
    \ l:ret.modules.cmake.get_configuration()

    let l:ret.properties.internal =
    \ {
    \   "temporary_ctags_file":
    \   l:ret.properties.configuration.temporary_directory . "/ctags",
    \
    \   "temporary_cscope_file":
    \   l:ret.properties.configuration.temporary_directory . "/cscope",
    \
    \   "project_name":
    \   l:ret.properties.configuration.cmake.settings.project_name,
    \
    \   "bin_directory":
    \   l:ret.properties.configuration.cmake.settings.bin_directory,
    \
    \   "is_project":
    \   filereadable(l:ret.properties.configuration.cmake.settings.input_file) &&
    \   isdirectory(l:ret.properties.configuration.source.settings.source_directory) &&
    \   filereadable(g:proset_settings_file) &&
    \   !empty(l:ret.properties.configuration.cmake.settings.project_name)
    \ }

    let l:ret.modules.run =
    \ proset#settings#cxx_cmake#run#construct(a:config,
    \       l:ret.properties.internal.bin_directory,
    \       l:ret.properties.internal.project_name)
    let l:ret.properties.configuration.run =
    \ l:ret.modules.run.get_configuration()

    let l:ret.modules.ctags =
    \ proset#settings#cxx_cmake#ctags#construct(a:config,
    \       l:ret.properties.internal.temporary_ctags_file,
    \       l:ret.properties.configuration.source.settings.source_directory)
    let l:ret.properties.configuration.ctags =
    \ l:ret.modules.ctags.get_configuration()

    let l:ret.modules.cscope =
    \ proset#settings#cxx_cmake#cscope#construct(a:config,
    \       l:ret.properties.internal.temporary_cscope_file,
    \       l:ret.properties.configuration.source.settings.source_directory)
    let l:ret.properties.configuration.cscope =
    \ l:ret.modules.cscope.get_configuration()

    let l:ret.modules.symbols =
    \ proset#settings#cxx_cmake#symbols#construct(a:config)
    let l:ret.properties.configuration.symbols =
    \ l:ret.modules.symbols.get_configuration()

    let l:ret.modules.alternate_file =
    \ proset#settings#cxx_cmake#alternate_file#construct(a:config,
    \       l:ret.properties.configuration.source.settings.header_extension,
    \       l:ret.properties.configuration.source.settings.source_extension)
    let l:ret.properties.configuration.alternate_file =
    \ l:ret.modules.alternate_file.get_configuration()

    let l:ret.modules.create_header =
    \ proset#settings#cxx_cmake#create_header#construct(a:config,
    \       l:ret.properties.internal.project_name,
    \       l:ret.properties.configuration.source.settings.header_extension,
    \       l:ret.properties.configuration.source.settings.source_extension)
    let l:ret.properties.configuration.create_header =
    \ l:ret.modules.create_header.get_configuration()

    let l:ret.modules.create_source =
    \ proset#settings#cxx_cmake#create_source#construct(a:config,
    \       l:ret.properties.internal.project_name,
    \       l:ret.properties.configuration.source.settings.header_extension,
    \       l:ret.properties.configuration.source.settings.source_extension)
    let l:ret.properties.configuration.create_source =
    \ l:ret.modules.create_source.get_configuration()

    let l:ret.modules.create_header_source =
    \ proset#settings#cxx_cmake#create_header_source#construct(a:config,
    \       l:ret.properties.internal.project_name,
    \       l:ret.properties.configuration.source.settings.header_extension,
    \       l:ret.properties.configuration.source.settings.source_extension)
    let l:ret.properties.configuration.create_header_source =
    \ l:ret.modules.create_header_source.get_configuration()

    return l:ret
endfunction

function! s:cxx_cmake.is_project()
    return self.properties.internal.is_project
endfunction

function! s:cxx_cmake.get_project_name()
    return self.properties.internal.project_name
endfunction

function! s:cxx_cmake.get_properties()
    return self.properties
endfunction

function! s:cxx_cmake.get_settings_name()
    return "cxx-cmake"
endfunction

function! s:cxx_cmake.enable() abort
    let l:tempdir = self.properties.configuration.temporary_directory

    call delete(l:tempdir, "rf")
    call mkdir(l:tempdir, "p")

    call s:enable_modules(self.modules)
endfunction

function! s:cxx_cmake.disable()
    call s:disable_modules(self.modules)

    call delete(self.properties.configuration.temporary_directory, "rf")
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
