if exists("g:autoloaded_proset_settings_cxx_cmake_create")
    finish
endif
let g:autoloaded_proset_settings_cxx_cmake_create = 1

function s:get_cmakelists_content(project_name, source_directory, source_extension, project_type)
    let l:str  = "cmake_minimum_required(VERSION 3.23)"
    let l:str .= "\n"
    let l:str .= "\n"
    let l:str .= "set(PROJECT_NAME \"" . a:project_name . "\")"
    let l:str .= "\n"
    let l:str .= "project(\"${PROJECT_NAME}\")"
    let l:str .= "\n"
    let l:str .= "\n"
    let l:str .= "set(CMAKE_CXX_STANDARD              \"17\")"
    let l:str .= "\n"
    let l:str .= "set(CMAKE_CXX_FLAGS                 \"-Wall -Wextra -Wpedantic -Werror=return-type -O2\")"
    let l:str .= "\n"
    let l:str .= "\n"

    let l:str .= "include_directories(\"" . a:source_directory . "\")"
    let l:str .= "\n"
    let l:str .= "\n"

    let l:str .= "set(SRC"
    let l:str .= "\n"
    let l:str .= "    \"" . a:source_directory . "/main." . a:source_extension . "\""
    let l:str .= "\n"
    let l:str .= ")"
    let l:str .= "\n"
    let l:str .= "\n"

    if a:project_type == "execute"
        let l:str .= "add_executable(\"${PROJECT_NAME}\" \"${SRC}\")"
    elseif a:project_type == "static"
        let l:str .= "add_library(\"${PROJECT_NAME}\" STATIC \"${SRC}\")"
    elseif a:project_type == "shared"
        let l:str .= "add_library(\"${PROJECT_NAME}\" SHARED \"${SRC}\")"
    endif

    let l:str .= "\n"
    let l:str .= "target_link_libraries(\"${PROJECT_NAME}\")"

    return split(l:str, "\n")
endfunction

function! s:get_main_content()
    let l:str  = "int main(int a_argc, char** a_argv)"
    let l:str .= "\n"
    let l:str .= "{"
    let l:str .= "\n"
    let l:str .= "    return 0;"
    let l:str .= "\n"
    let l:str .= "}"

    return split(l:str, "\n")
endfunction

function! proset#settings#cxx_cmake#create#create_main_file(source_directory_path, source_extension)
    let l:file = a:source_directory_path . "/main." . a:source_extension
    let l:cont = s:get_main_content()
    call writefile(l:cont, l:file)
endfunction

function! proset#settings#cxx_cmake#create#create_cmakelists_file(project_path,
    \       project_name,
    \       project_type,
    \       source_directory,
    \       source_extension,
    \       cmake_input_filename)

    let l:file = a:project_path . "/" . a:cmake_input_filename
    let l:cont = s:get_cmakelists_content(a:project_name,
    \               a:source_directory,
    \               a:source_extension,
    \               a:project_type)
    call writefile(l:cont, l:file)
endfunction

function! proset#settings#cxx_cmake#create#convert_mappings(mappings)
    let l:ret = {}

    for l:key in keys(a:mappings)
        let l:ret[l:key] = a:mappings[l:key].sequence
    endfor

    return l:ret
endfunction

function! proset#settings#cxx_cmake#create#get_settings_content(modules)
    let l:ret                      = {}
    let l:ret.alternate_file       = a:modules.alternate_file.get_module_properties()
    let l:ret.build                = a:modules.build.get_module_properties()
    let l:ret.create_header        = a:modules.create_header.get_module_properties()
    let l:ret.create_header_source = a:modules.create_header_source.get_module_properties()
    let l:ret.create_source        = a:modules.create_source.get_module_properties()
    let l:ret.cscope               = a:modules.cscope.get_module_properties()
    let l:ret.ctags                = a:modules.ctags.get_module_properties()
    let l:ret.run                  = a:modules.run.get_module_properties()
    let l:ret.source               = a:modules.source.get_module_properties()
    let l:ret.symbols              = a:modules.symbols.get_module_properties()
    let l:ret.temporary            = a:modules.temporary.get_module_properties()
    return l:ret
endfunction
