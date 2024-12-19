" Proset - Project Settings Loader
"
" Author:     Artur Pyszczuk <apyszczuk@gmail.com>
" License:    Same terms as Vim itself
" Website:    https://github.com/apyszczuk/vim-proset

if exists("g:loaded_proset")
    finish
endif
let g:loaded_proset = 1

let g:proset_settings_file
\ = get(g:, "proset_settings_file", ".vim-proset/settings.json")
lockvar g:proset_settings_file

if !exists("g:proset_json_encoder")
    let g:proset_json_encoder =
    \ {
    \   "function": "proset#lib#json_encode#encode",
    \   "options":
    \   {
    \       "indent_init_level":    "0",
    \       "indent_width":         "4",
    \       "value_column_start":   "50"
    \   }
    \ }
endif

let s:settings          = proset#settings#default#construct()
let s:storage           = {}
let s:configuration     = {}

function! s:enable()
    if ProsetIsProject()
        call s:settings.enable()
    endif
endfunction

function! s:disable()
    if ProsetIsProject()
        call s:settings.disable()
    endif
endfunction

function! s:get_error_number_and_message(error_number, message)
    return a:error_number . "|" . a:message
endfunction

function! s:load_settings(path, init_phase)
    let l:cwd_orig = getcwd()

    try
        try
            let l:settings_file = a:path . "/" . g:proset_settings_file

            if !filereadable(l:settings_file)
                if a:init_phase == 0
                    let l:msg = "Configuration file is missing"
                    throw s:get_error_number_and_message(20, l:msg)
                endif

                return 1
            endif

            let l:cfg = json_decode(join(readfile(l:settings_file), "\n"))
            let l:name = proset#lib#dict#get(l:cfg, "", "proset_settings")

            if empty(l:name)
                let l:msg = "'proset_settings' is empty or missing"
                throw s:get_error_number_and_message(21, l:msg)
            endif

            if !has_key(s:storage, l:name)
                let l:msg = l:name . " is not supported"
                throw s:get_error_number_and_message(30, l:msg)
            endif

            noautocmd call chdir(a:path)
            let Constructor     = function(s:storage[l:name])
            let l:settings_tmp  = Constructor(l:cfg, {"mode": "load"})

            " This is important becuase calling disable on Settings Object
            " expects to be in project root path, yet it was switched due to
            " construction of Settings Object above
            noautocmd call chdir(l:cwd_orig)
            call s:disable()

            " And go back to project root path of loaded project
            noautocmd call chdir(a:path)

            let s:settings      = deepcopy(l:settings_tmp)
            let s:configuration = deepcopy(l:cfg)

            if a:init_phase == 0
                call s:enable()
                :redraw!
                call proset#print#print_info(ProsetGetSettingsName(), ProsetGetProjectName() . " was loaded")
            else
                autocmd VimEnter *
                \ call proset#print#print_info(ProsetGetSettingsName(), ProsetGetProjectName() . " was loaded")
            endif

            if exists('#User#ProsetSettingsChosenEvent')
                doautocmd User ProsetSettingsChosenEvent
            endif

            if len(autocmd_get(#{group: 'Proset', event: 'DirChangedPre'})) == 0
                autocmd Proset DirChangedPre * :call ProsetClose()
            endif
            return 0

        catch /^proset:construct-settings:/
            let l:lst = split(v:exception, ":")
            let l:msg = l:lst[2] . ": " . l:lst[3]
            throw s:get_error_number_and_message(40, l:msg)
        catch /^Vim\%((\a\+)\)\=:E491:/
            let l:msg = "Configuration file syntax error (Vim:E491)"
            throw s:get_error_number_and_message(22, l:msg)
        catch /^Vim\%((\a\+)\)\=:E938:/
            let l:msg = "Configuration file syntax error (Vim:E938)"
            throw s:get_error_number_and_message(23, l:msg)
        endtry
    catch /\%(\d\+\)|.*/
        noautocmd call chdir(l:cwd_orig)
        let s:data = split(v:exception, "|")

        if a:init_phase == 0
            call proset#print#print_error(s:data[0], s:data[1])
        else
            autocmd VimEnter * call proset#print#print_error(s:data[0], s:data[1])
        endif

        return s:data[0]
    endtry
endfunction

function! s:add_commands()
    command! -nargs=1 -complete=dir ProsetLoad   :call ProsetLoad(<f-args>)
    command! -nargs=0               ProsetClose  :call ProsetClose()
    command! -nargs=0               ProsetReload :call ProsetReload()

    " Add custom complete for supported(registered) settings_name
    command! -nargs=+ -complete=dir ProsetCreate :call ProsetCreate(<f-args>)
endfunction

function! s:remove_commands()
    for l:cmd in getcompletion("Proset", "command")
        execute "delcommand " . l:cmd
    endfor
endfunction

function! s:validate_settings_file()
    if proset#lib#path#is_subpath(getcwd(), g:proset_settings_file) == 0
        throw "proset:init-phase:1:'g:proset_settings_file' is incorrect"
    endif
endfunction

function! ProsetRegisterSettings(settings_name, constructor_name)
    if has_key(s:storage, a:settings_name)
        throw "proset:register-settings:" . a:settings_name
    endif

    let s:storage[a:settings_name] = a:constructor_name
endfunction

function! ProsetIsProject()
    return s:settings.is_project()
endfunction

function! ProsetGetSettingsName()
    return s:settings.get_settings_name()
endfunction

function! ProsetGetProjectName()
    return s:settings.get_project_name()
endfunction

function! ProsetGetProperties()
    return deepcopy(s:settings.get_properties())
endfunction

function! ProsetGetConfiguration()
    return deepcopy(s:configuration)
endfunction

function! ProsetLoad(path)
    return s:load_settings(a:path, 0)
endfunction

function! ProsetReload()
    return ProsetLoad(".")
endfunction

function! ProsetClose()
    autocmd! Proset DirChangedPre *
    let l:project_name  = ProsetGetProjectName()
    let l:is_project    = ProsetIsProject()
    let l:settings_name = ProsetGetSettingsName()

    call s:disable()
    let s:settings      = proset#settings#default#construct()
    let s:configuration = {}

    if l:is_project
        call proset#print#print_info(l:settings_name, l:project_name . " was closed")
    endif
endfunction

function! s:remove_slashes(str)
    let l:str = a:str
    while len(l:str) > 0 && strpart(l:str, len(l:str)-1, 1) == "/"
        let l:str = strpart(l:str, 0, len(l:str)-1)
    endwhile
    return l:str
endfunction

function! ProsetCreate(settings_name, path, ...)
    let l:path = s:remove_slashes(simplify(fnamemodify(trim(a:path), ":p")))
    try
        if !has_key(s:storage, a:settings_name)
            call proset#print#print_error(50, a:settings_name . " is not registered")
            return
        endif

        let l:settings_file         = l:path . "/" . g:proset_settings_file
        let l:settings_directory    = fnamemodify(l:settings_file, ":p:h")

        if isdirectory(l:path)
            call proset#print#print_error(51, "Can not use existing directory")
            return
        endif

        call mkdir(l:settings_directory, "p")

        let Constructor             = function(s:storage[a:settings_name])
        let l:settings_tmp          = Constructor({}, {"mode": "create"})

        let l:rv = l:settings_tmp.create(l:path, a:000)
        let l:rv.dictionary.proset_settings = a:settings_name

        let Encoder     = function(g:proset_json_encoder.function)
        let l:string    = Encoder(l:rv.dictionary, g:proset_json_encoder.options)
        let l:content   = split(l:string, "\n")

        call writefile(l:content, l:settings_file)

        call proset#print#print_info(a:settings_name, l:rv.project_name . " was created at " . l:path)
        return
    catch /^proset:construct-settings:/
        let l:lst = split(v:exception, ":")
        let l:msg = a:settings_name . ": " . l:lst[3]
        call proset#print#print_error(52, l:msg)
    catch /^proset:create:/
        let l:lst = split(v:exception, ":")
        let l:msg = a:settings_name . ": " . l:lst[2]
        call proset#print#print_error(53, l:msg)
    catch
        let l:msg = a:settings_name . ": " . v:exception
        call proset#print#print_error(54, l:msg)
    endtry

    call delete(l:path, "rf")
endfunction


augroup Proset
    autocmd!

    try
        call s:validate_settings_file()

        autocmd VimEnter * call s:enable()
        autocmd VimLeave * call s:disable()

        if exists('#User#ProsetRegisterInternalSettingsEvent')
            doautocmd User ProsetRegisterInternalSettingsEvent
        endif

        if exists('#User#ProsetRegisterSettingsEvent')
            doautocmd User ProsetRegisterSettingsEvent
        endif

        call s:load_settings(".", 1)

        call s:add_commands()
    catch /^proset:register-settings:/
        let lst  = split(v:exception, ":")
        autocmd VimEnter * call proset#print#print_error(10, lst[2] . " is already registered")

        " without this, one can load Settings Object that was already
        " registered. Registering two Settings Objects with the same name is
        " an error. Names must be unique to make this plugin work.
        let s:storage = {}
        call s:remove_commands()

    catch /^proset:init-phase:/
        let lst = split(v:exception, ":")
        autocmd VimEnter * call proset#print#print_error(lst[2], join(lst[3:], ":"))
    endtry

augroup END
