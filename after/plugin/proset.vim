" Proset - Project Settings Loader
"
" Author:     Artur Pyszczuk <apyszczuk@gmail.com>
" License:    Same terms as Vim itself
" Website:    https://github.com/apyszczuk/vim-proset

if exists("g:loaded_proset")
    finish
endif
let g:loaded_proset = 1

let g:proset_settings_file = get(g:,
\                               "proset_settings_file",
\                               ".vim-proset/settings.json")
lockvar g:proset_settings_file

let s:settings          = proset#settings#default#construct()
let s:storage           = {}
let s:configuration     = {}

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

function! s:get_info_message(msg)
    return "proset: " . a:msg . "."
endfunction

function! s:get_error_message(num, msg)
    return "proset-E" . a:num . ": " . a:msg . "."
endfunction

function! s:get_error_number_and_message(num, msg)
    return a:num . "|" . s:get_error_message(a:num, a:msg)
endfunction

function! s:get_project_info(project_name, settings_name)
    return a:project_name . "(" . a:settings_name . ")"
endfunction

function! s:print_message(message)
    echohl WarningMsg | echom a:message | echohl None
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
                let l:msg = "Configuration parameter proset_settings "
                \           . "is empty or missing"
                throw s:get_error_number_and_message(21, l:msg)
            endif

            if !has_key(s:storage, l:name)
                let l:msg = "Not supported Settings Object (" . l:name . ")"
                throw s:get_error_number_and_message(30, l:msg)
            endif

            noautocmd call chdir(a:path)
            let Constructor     = function(s:storage[l:name])
            let l:settings_tmp  = Constructor(l:cfg)

            " This is important becuase calling disable on Settings Object
            " expects to be in project root path, yet it was switched due to
            " construction of Settings Object above
            noautocmd call chdir(l:cwd_orig)
            call s:disable()

            " And go back to project root path of loaded project
            noautocmd call chdir(a:path)

            let s:settings      = deepcopy(l:settings_tmp)
            let s:configuration = deepcopy(l:cfg)

            let l:pro_info      = s:get_project_info(ProsetGetProjectName(),
            \                       ProsetGetSettingsName())
            let s:success_msg   = s:get_info_message(l:pro_info . " was loaded")

            if a:init_phase == 0
                call s:enable()
                :redraw!
                call s:print_message(s:success_msg)
            else
                autocmd VimEnter * call s:print_message(s:success_msg)
            endif

            if exists('#User#ProsetSettingsChosenEvent')
                doautocmd User ProsetSettingsChosenEvent
            endif

            if len(autocmd_get(#{group: 'Proset', event: 'DirChangedPre'})) == 0
                autocmd Proset DirChangedPre * :call ProsetCloseSettings()
            endif
            return 0

        catch /^proset:construct-settings:/
            let l:lst = split(v:exception, ":")
            let l:msg = "Can not construct Settings Object (" . l:lst[2] . "): "
            \           . l:lst[3]
            throw s:get_error_number_and_message(40, l:msg)
        catch /^Vim\%((\a\+)\)\=:E491:/
            let l:msg = "Configuration file syntax error (Vim:E491)"
            throw s:get_error_number_and_message(22, l:msg)
        catch /^Vim\%((\a\+)\)\=:E938:/
            let l:msg = "Configuration file syntax error (Vim:E938)"
            throw s:get_error_number_and_message(23, l:msg)
        endtry
    catch /\%(\d\+\)|proset-E\%(\d\+\):.*/
        noautocmd call chdir(l:cwd_orig)

        let l:lst       = split(v:exception, "|")
        let s:error_msg = l:lst[1]

        if a:init_phase == 0
            call s:print_message(s:error_msg)
        else
            autocmd VimEnter * call s:print_message(s:error_msg)
        endif

        return l:lst[0]
    endtry
endfunction

function! ProsetLoadSettings(path)
    return s:load_settings(a:path, 0)
endfunction

function! ProsetReloadSettings()
    return ProsetLoadSettings(".")
endfunction

function! ProsetCloseSettings()
    autocmd! Proset DirChangedPre *
    let l:project_name  = ProsetGetProjectName()
    let l:is_project    = ProsetIsProject()
    let l:settings_name = ProsetGetSettingsName()

    call s:disable()
    let s:settings      = proset#settings#default#construct()
    let s:configuration = {}

    if l:is_project
        let l:msg = s:get_project_info(l:project_name, l:settings_name)
        call s:print_message(l:msg . " was closed.")
    endif

endfunction

function! s:add_commands()
    command! -nargs=1 -complete=dir ProsetLoadSettings
    \   :call ProsetLoadSettings(<f-args>)

    command! -nargs=0 ProsetCloseSettings  :call ProsetCloseSettings()
    command! -nargs=0 ProsetReloadSettings :call ProsetReloadSettings()
endfunction

function! s:remove_commands()
    for l:cmd in getcompletion("Proset", "command")
        execute "delcommand " . l:cmd
    endfor
endfunction

function! s:validate_settings_file()
    if proset#utils#path#is_subpath(getcwd(), g:proset_settings_file) == 0
        throw "proset:init-phase:1:bad g:proset_settings_file value"
    endif
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
        let desc = "Settings Object (" . lst[2] . ") is already registered"
        let msg  = s:get_error_message(10, desc)
        autocmd VimEnter * call s:print_message(msg)

        " without this, one can load Settings Object that was already
        " registered. Registering two Settings Objects with the same name is
        " an error. Names must be unique to make this plugin work.
        let s:storage = {}
        call s:remove_commands()

    catch /^proset:init-phase:/
        let lst = split(v:exception, ":")
        let msg = s:get_error_message(lst[2], join(lst[3:], ":"))
        autocmd VimEnter * call s:print_message(msg)
    endtry

augroup END
