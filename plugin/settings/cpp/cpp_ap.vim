if exists("g:loaded_proset_settings_cpp_cpp_ap")
    finish
endif
let g:loaded_proset_settings_cpp_cpp_ap = 1

function! s:generate_tags_file(additional_ctags_directories, build_directory, temporary_ctags_file)
    let l:cmd = proset#utils#ctags#get_ctags_command(
                \ a:additional_ctags_directories,
                \ a:build_directory,
                \ a:temporary_ctags_file)
    silent execute '!' . l:cmd
endfunction

function! s:generate_cscope_file(additional_cscope_directories, temporary_cscope_file)
    silent execute "!" . proset#utils#cscope#get_cscope_command(
                \ a:additional_cscope_directories,
                \ a:temporary_cscope_file)
endfunction

function! s:set_makeprg(build_directory, jobs_number)
    let l:cmd = proset#utils#cmake#get_build_command(a:build_directory, a:jobs_number)
    silent execute "set makeprg=" . l:cmd
endfunction

function! s:set_commands(build_directory, project_name)
    execute "command! -nargs=0 ProsetBuild " . ":wa \| :AsyncRun -program=make"
    execute "command! -nargs=* ProsetRun "   . "term " . a:build_directory . "/" . a:project_name . " <args>"
    execute "command! -nargs=0 ProsetClean " . "call delete(\"" . a:build_directory . "\", \"rf\")"
endfunction

function! s:set_cscope_mapping(command)
    execute 'nnoremap <silent> me' . a:command . ' :cs find ' . a:command . ' <C-R>=expand("<cword>")<CR><CR>'
endfunction

function! s:set_cscope_mappings()
    call s:set_cscope_mapping("a")
    call s:set_cscope_mapping("c")
    call s:set_cscope_mapping("d")
    call s:set_cscope_mapping("e")
    call s:set_cscope_mapping("f")
    call s:set_cscope_mapping("g")
    call s:set_cscope_mapping("i")
    call s:set_cscope_mapping("s")
    call s:set_cscope_mapping("t")
endfunction

function! s:set_mappings(additional_ctags_directories,
                        \ build_directory,
                        \ temporary_ctags_file,
                        \ additional_cscope_directories,
                        \ temporary_cscope_file,
                        \ external_cscope_files)
    " TODO to be changed to my alternative-file
    " nnoremap <silent> ma :A<CR>

    call s:set_cscope_mappings()
    nnoremap <silent> mk :ProsetBuild<CR>
    nnoremap <silent> mK :ProsetClean<CR> :ProsetBuild<CR>
    nnoremap <silent> mr :ProsetRun<CR>
    nnoremap          mR :ProsetRun 
    let l:mu_cmd = 'nnoremap <silent> mu :call <SID>generate_tags_file(' .
                \ '"' . a:additional_ctags_directories . '", ' .
                \ '"' . a:build_directory . '", ' .
                \ '"' . a:temporary_ctags_file . '"' .
                \ ') ' .
                \ '\| :call <SID>generate_cscope_file(' .
                \ '"' . a:additional_cscope_directories . '", ' .
                \ '"' . a:temporary_cscope_file . '"' .
                \ ') ' .
                \ '\| :call proset#utils#cscope#add_cscope_files(' .
                \ '"' . a:temporary_cscope_file . '", ' .
                \ '"' . a:external_cscope_files . '"' .
                \ ') ' .
                \ '\| :redraw!<CR>'
    execute '' . l:mu_cmd

endfunction

function! s:prepare_header_guard_string(project_name, path, filename_header)
    let l:path  = a:path
    let l:sz    = len(l:path)-1
    if strpart(l:path, l:sz, 1) == "/"
        let l:path = strpart(l:path, 0, l:sz)
    endif

    let l:path              = substitute(l:path, "/", "_", "g")
    let l:filename_header   = substitute(a:filename_header, '\.', "_", "")
    return toupper(a:project_name . "_" . l:path . "_" . l:filename_header)
endfunction

function! s:create_header(project_name, path, filename_header, notused)
    let l:guard_string = s:prepare_header_guard_string(a:project_name, a:path, a:filename_header)

    let l:file_content  = "#ifndef " . l:guard_string . "\n"
    let l:file_content .= "#define " . l:guard_string . "\n\n\n"
    let l:file_content .= "#endif // " . l:guard_string

    call writefile(split(l:file_content, "\n"), a:path . "/" . a:filename_header)
endfunction

function! s:create_source(project_name, path, filename_source, extensions)
    let l:filename_header = substitute(a:filename_source,
                                        \ "." . a:extensions[1],
                                        \ "." . a:extensions[0],
                                        \ "g")
    let l:file_content = "#include \"" . l:filename_header . "\"\n"
    call writefile(split(l:file_content, "\n"), a:path . "/" . a:filename_source)
endfunction

function! s:create_module(project_name, path, module_name, extensions)
    call s:create_header(a:project_name, a:path, a:module_name . a:extensions[0], "")
    call s:create_source(a:project_name, a:path, a:module_name . a:extensions[1], a:extensions)
endfunction

function! s:nerdtree_menu_item(item_description, item_function, project_name, extension, extensions)
    let l:selected_dir  = g:NERDTreeDirNode.GetSelected().path.str() . '/'
    let l:project_path  = getcwd() . '/'
    let l:item          = input("Enter C++ " . a:item_description . " filename (no extension): ",
                                \ "",
                                \ "file")
    let l:path = substitute(l:selected_dir, l:project_path, "", "")

    if l:item ==# ''
        call nerdtree#echo(a:item_description . " has to have name. Aborting...")
        return
    endif

    let Act = function(a:item_function)
    call Act(a:project_name, l:path, l:item . "." . a:extension, a:extensions)
    call b:NERDTree.root.refresh()
    call NERDTreeRender()
endfun

function! s:nerdtree_menu_item_header_file(project_name, header_extension)
    call s:nerdtree_menu_item("Header", "s:create_header", a:project_name, a:header_extension, "")
endfunction

function! s:nerdtree_menu_item_source_file(project_name, header_extension, source_extension)
    call s:nerdtree_menu_item("Source", "s:create_source", a:project_name, a:source_extension, [a:header_extension, a:source_extension])
endfunction

function! s:nerdtree_menu_item_module(project_name, header_extension, source_extension)
    call s:nerdtree_menu_item("Module", "s:create_module", a:project_name, "", [a:header_extension, a:source_extension])
endfunction

function! s:nerdtree_menu_properties(project_name, header_extension, source_extension)
    function! s:nerdtree_menu_item_header_file_closure() closure
        call s:nerdtree_menu_item_header_file(a:project_name, a:header_extension)
    endfunction

    function! s:nerdtree_menu_item_source_file_closure() closure
        call s:nerdtree_menu_item_source_file(a:project_name, a:header_extension, a:source_extension)
    endfunction

    function! s:nerdtree_menu_item_module_closure() closure
        call s:nerdtree_menu_item_module(a:project_name, a:header_extension, a:source_extension)
    endfunction

    return {
        \ 'header': {'text': '(1) Create C++ files', 'shortcut': '1'},
        \ 'items':
        \ [
        \ {
        \   'text': 'Create a C++ (h)eader file',
        \   'shortcut': 'h',
        \   'callback': function('<SID>nerdtree_menu_item_header_file_closure'),
        \   'parent': ''
        \ },
        \ {
        \   'text': 'Create a C++ (s)ource file',
        \   'shortcut': 's',
        \   'callback': function('<SID>nerdtree_menu_item_source_file_closure'),
        \   'parent': ''
        \ },
        \ {
        \   'text': 'Create a C++ (m)odule',
        \   'shortcut': 'm',
        \   'callback': function('<SID>nerdtree_menu_item_module_closure'),
        \   'parent': ''
        \ }
        \ ]
  \ }
endfunction


let s:cpp_ap = {'properties': {}}

function! s:get_string_non_empty(config, key, default_value)
    let l:ret = a:config.get(a:key, a:default_value)
    if empty(l:ret)
        throw "proset:settings:cpp:" . s:cpp_ap.get_settings_name() . ":" . a:key . " is empty"
    endif
    return l:ret
endfunction

function! s:cpp_ap.construct(config)
    let l:ret = deepcopy(self)

    let l:ret.properties["settings_directory"]              = g:proset_directory
    let l:ret.properties["temporary_directory"]             = s:get_string_non_empty(a:config, "temporary_directory", ".project_tmp")

    let l:ret.properties["build_directory"]                 = s:get_string_non_empty(a:config, "build_directory", "build")
    let l:ret.properties["source_directory"]                = s:get_string_non_empty(a:config, "source_directory", "src")
    let l:ret.properties["jobs_number"]                     = a:config.get("jobs_number", "1")

    let l:ret.properties["temporary_ctags_file"]            = l:ret.properties["temporary_directory"] . "/tags"
    let l:ret.properties["additional_ctags_directories"]    = a:config.get("additional_ctags_directories", "")
    let l:ret.properties["external_ctags_files"]            = a:config.get("external_ctags_files", "")

    let l:ret.properties["temporary_cscope_file"]           = l:ret.properties["temporary_directory"] . "/cscope"
    let l:ret.properties["additional_cscope_directories"]   = a:config.get("additional_cscope_directories", "")
    let l:ret.properties["external_cscope_files"]           = a:config.get("external_cscope_files", "")

    let l:ret.properties["additional_search_directories"]   = a:config.get("additional_search_directories", "")

    let l:ret.properties["cmakelists_file"]                 = "CMakeLists.txt"
    let l:ret.properties["project_name"]                    = proset#utils#cmake#get_project_name(l:ret.properties["cmakelists_file"])
    let l:ret.properties["is_project"]                      = filereadable(l:ret.properties["cmakelists_file"]) &&
                                                            \ isdirectory(l:ret.properties["source_directory"]) &&
                                                            \ isdirectory(l:ret.properties["settings_directory"])


    let l:ret.properties["header_extension"]                = s:get_string_non_empty(a:config, "header_extension", "hpp")
    let l:ret.properties["source_extension"]                = s:get_string_non_empty(a:config, "source_extension", "cpp")

    let l:ret.properties['nerdtree_menu_properties']        = s:nerdtree_menu_properties(l:ret.properties["project_name"],
                                                                                       \ l:ret.properties["header_extension"],
                                                                                       \ l:ret.properties["source_extension"])

    return l:ret
endfunction

function! s:cpp_ap.is_project()
    return self.properties["is_project"]
endfunction

function! s:cpp_ap.get_project_name()
    return self.properties["project_name"]
endfunction

function! s:cpp_ap.get_properties()
    return self.properties
endfunction

function! s:cpp_ap.get_settings_name()
    return "cpp-ap"
endfunction

function! s:cpp_ap.enable() abort
    let l:temporary_directory           = self.properties["temporary_directory"]
    let l:build_directory               = self.properties["build_directory"]
    let l:jobs_number                   = self.properties["jobs_number"]
    let l:project_name                  = self.properties["project_name"]
    let l:temporary_ctags_file          = self.properties["temporary_ctags_file"]
    let l:additional_ctags_directories  = self.properties["additional_ctags_directories"]
    let l:external_ctags_files          = self.properties["external_ctags_files"]
    let l:temporary_cscope_file         = self.properties["temporary_cscope_file"]
    let l:additional_cscope_directories = self.properties["additional_cscope_directories"]
    let l:external_cscope_files         = self.properties["external_cscope_files"]
    let l:additional_search_directories = self.properties["additional_search_directories"]

    call delete(l:temporary_directory, "rf")
    call mkdir(l:temporary_directory)

    call s:set_makeprg(l:build_directory, l:jobs_number)
    call s:set_commands(l:build_directory, l:project_name)
    call s:set_mappings(l:additional_ctags_directories,
                        \ l:build_directory,
                        \ l:temporary_ctags_file,
                        \ l:additional_cscope_directories,
                        \ l:temporary_cscope_file,
                        \ l:external_cscope_files)

    let &tags = proset#utils#ctags#get_tags_filenames(l:temporary_ctags_file, l:external_ctags_files)
    call s:generate_tags_file(l:additional_ctags_directories, l:build_directory, l:temporary_ctags_file)
    call s:generate_cscope_file(l:additional_cscope_directories, l:temporary_cscope_file)
    call proset#utils#cscope#add_cscope_files(l:temporary_cscope_file, l:external_cscope_files)
    let &path .= substitute(l:additional_search_directories, ";", ",", "g")
endfunction

" todo: revert enable() if settings object can be switched without closing
" vim
function! s:cpp_ap.disable()
    call delete(self.properties["temporary_directory"], "rf")
endfunction

autocmd User ProsetRegisterInternalSettingsEvent
        \ call ProsetRegisterSettings(
        \ s:cpp_ap.construct(ProsetGetConfiguration()))
