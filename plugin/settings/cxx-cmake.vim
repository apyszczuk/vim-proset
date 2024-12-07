" cxx-cmake - CXX CMake Settings Dictionary
"
" Author:     Artur Pyszczuk <apyszczuk@gmail.com>
" License:    Same terms as Vim itself
" Website:    https://github.com/apyszczuk/vim-proset

if exists("g:loaded_proset_settings_cxx_cmake")
    finish
endif
let g:loaded_proset_settings_cxx_cmake = 1

function! s:get_project_type(args)
    let l:ret = len(a:args) == 0 ? "execute" : a:args[0]

    if (l:ret != "execute") &&
    \  (l:ret != "static")  &&
    \  (l:ret != "shared")
        throw "proset:create:invalid project type"
    endif

    return l:ret
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

let s:cxx_cmake = {'properties': {}, 'modules': {}}

function! s:cxx_cmake.construct(config)
    let l:ret = deepcopy(self)

    let l:ret.modules.temporary =
    \ proset#settings#cxx_cmake#modules#temporary#construct(a:config)
    let l:ret.properties.temporary =
    \ l:ret.modules.temporary.get_properties()

    let l:ret.modules.build =
    \ proset#settings#cxx_cmake#modules#build#construct(a:config)
    let l:ret.properties.build =
    \ l:ret.modules.build.get_properties()

    let l:ret.modules.source =
    \ proset#settings#cxx_cmake#modules#source#construct(a:config)
    let l:ret.properties.source =
    \ l:ret.modules.source.get_properties()

    let l:ret.modules.cmake =
    \ proset#settings#cxx_cmake#modules#cmake#construct(a:config,
    \   l:ret.properties.build.settings.build_directory,
    \   l:ret.properties.source.settings.source_directory,
    \   g:proset_settings_file)
    let l:ret.properties.cmake =
    \ l:ret.modules.cmake.get_properties()

    let l:ret.modules.ctags =
    \ proset#settings#cxx_cmake#modules#ctags#construct(a:config,
    \       l:ret.properties.source.settings.source_directory,
    \       l:ret.properties.temporary.settings.temporary_directory)
    let l:ret.properties.ctags =
    \ l:ret.modules.ctags.get_properties()

    let l:ret.modules.cscope =
    \ proset#settings#cxx_cmake#modules#cscope#construct(a:config,
    \       l:ret.properties.source.settings.source_directory,
    \       l:ret.properties.temporary.settings.temporary_directory)
    let l:ret.properties.cscope =
    \ l:ret.modules.cscope.get_properties()

    let l:ret.modules.run =
    \ proset#settings#cxx_cmake#modules#run#construct(a:config,
    \       l:ret.properties.cmake.settings.bin_directory,
    \       l:ret.properties.cmake.settings.project_name)
    let l:ret.properties.run =
    \ l:ret.modules.run.get_properties()

    let l:ret.modules.symbols =
    \ proset#settings#cxx_cmake#modules#symbols#construct(a:config)
    let l:ret.properties.symbols =
    \ l:ret.modules.symbols.get_properties()

    let l:ret.modules.alternate_file =
    \ proset#settings#cxx_cmake#modules#alternate_file#construct(a:config,
    \       l:ret.properties.source.settings.header_extension,
    \       l:ret.properties.source.settings.source_extension)
    let l:ret.properties.alternate_file =
    \ l:ret.modules.alternate_file.get_properties()

    let l:ret.modules.create_header =
    \ proset#settings#cxx_cmake#modules#create_header#construct(a:config,
    \       l:ret.properties.cmake.settings.project_name,
    \       l:ret.properties.source.settings.header_extension,
    \       l:ret.properties.source.settings.source_extension)
    let l:ret.properties.create_header =
    \ l:ret.modules.create_header.get_properties()

    let l:ret.modules.create_source =
    \ proset#settings#cxx_cmake#modules#create_source#construct(a:config,
    \       l:ret.properties.cmake.settings.project_name,
    \       l:ret.properties.source.settings.header_extension,
    \       l:ret.properties.source.settings.source_extension)
    let l:ret.properties.create_source =
    \ l:ret.modules.create_source.get_properties()

    let l:ret.modules.create_header_source =
    \ proset#settings#cxx_cmake#modules#create_header_source#construct(a:config,
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
    let l:tempdir = self.properties.temporary.settings.temporary_directory

    call delete(l:tempdir, "rf")
    call mkdir(l:tempdir, "p")

    call s:enable_modules(self.modules)
endfunction

function! s:cxx_cmake.disable()
    call s:disable_modules(self.modules)

    call delete(self.properties.temporary.settings.temporary_directory, "rf")
endfunction

function! s:cxx_cmake.create(project_path, args)
    let l:project_type = s:get_project_type(a:args)
    let l:project_name = fnamemodify(a:project_path, ":t")

    let l:source_extension      = self.properties.source.settings.source_extension
    let l:source_directory      = self.properties.source.settings.source_directory
    let l:source_directory_path = a:project_path . "/" . l:source_directory
    let l:cmake_input_filename  = self.properties.cmake.settings.input_file
    call mkdir(l:source_directory_path, "p")

    call proset#settings#cxx_cmake#create#create_cmakelists_file(a:project_path,
    \       l:project_name,
    \       l:project_type,
    \       l:source_directory,
    \       l:source_extension,
    \       l:cmake_input_filename)
    call proset#settings#cxx_cmake#create#create_main_file(l:source_directory_path,
    \       l:source_extension)

    return
    \ {
    \     "dictionary":
    \     proset#settings#cxx_cmake#create#get_settings_content(self.modules),
    \     "project_name":
    \     l:project_name
    \ }
endfunction

autocmd User ProsetRegisterInternalSettingsEvent
    \ call ProsetRegisterSettings("cxx-cmake", "CXXCMakeConstruct")

if !exists("g:cxx_cmake_input_template") || !filereadable(g:cxx_cmake_input_template)
    let g:cxx_cmake_input_template =
    \ simplify(
    \   expand("<script>:p:h")
    \   . "/../../autoload/proset/settings/cxx_cmake/resources/cxx-cmake-template.json"
    \ )
endif

function! CXXCMakeConstruct(config, options)
    let l:mode = a:options.mode

    if l:mode == "load"
        let l:config = a:config
    elseif l:mode == "create"
        let l:config = json_decode(join(readfile(g:cxx_cmake_input_template), "\n"))
    else
    endif

    return s:cxx_cmake.construct(l:config)
endfunction

