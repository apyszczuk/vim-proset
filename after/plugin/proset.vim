" Proset - Project Settings Loader
"
" Maintainer:   Artur Pyszczuk <apyszczuk@gmail.com>
" Version:      wip
" License:      This file is placed in the public domain.

if exists("g:loaded_proset")
    finish
endif
let g:loaded_proset = 1

let g:proset_directory  = get(g:, 'proset_directory', '.vim-proset')
let g:proset_file       = get(g:, 'proset_file', 'settings')

let s:proset_filepath   = g:proset_directory . "/" . g:proset_file

" default value
let s:settings          = proset#settings#default#construct()

" Settings Objects
let s:storage           = []

function! s:get_settings_from_name(settings_name)
    for item in s:storage
        if item.get_settings_name() == a:settings_name
            return item
        endif
    endfor
    return proset#settings#default#construct()
endfunction

function! ProsetRegisterSettings(settings)
    let l:name = a:settings.get_settings_name()
    " echo l:name
    for item in s:storage
        if l:name == item.get_settings_name()
            throw "proset:settings-already-registered:" . l:name
        endif
    endfor
    call add(s:storage, a:settings)
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
    return s:settings.get_properties()
endfunction

function! ProsetGetConfiguration()
    return s:configuration
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

function! s:print_error_message(str)
    echo "Proset Exception: " . a:str . ". Default Settings Object was chosen."
endfunction

augroup Proset
    autocmd!

    try
        let s:configuration = proset#lib#configuration#parse_file(s:proset_filepath, ":")
        const settings_name = s:configuration.get("proset_settings", "")
        if empty(settings_name)
            finish
        endif

        if exists('#User#ProsetRegisterInternalSettingsEvent')
            doautocmd User ProsetRegisterInternalSettingsEvent
        endif

        if exists('#User#ProsetRegisterSettingsEvent')
            doautocmd User ProsetRegisterSettingsEvent
        endif

        let s:settings = s:get_settings_from_name(settings_name)

        if exists('#User#ProsetSettingsChosenEvent')
            doautocmd User ProsetSettingsChosenEvent
        endif

        autocmd VimEnter * call s:enable()
        autocmd VimLeave * call s:disable()

    catch /^proset:settings-already-registered:/
        let lst = split(v:exception, ":")
        call s:print_error_message(lst[2] . ": already registered")
        finish
    catch /^proset:settings:/
        let lst = split(v:exception, ":")
        call s:print_error_message(lst[3] . ": " . lst[4])
        finish
    catch /^proset:configuration:/
        let lst = split(v:exception, ":")
        call s:print_error_message(lst[2] . ": " . lst[3])
        finish
    endtry
augroup END
