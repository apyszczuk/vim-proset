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

function! s:load(path, init_phase)
    let l:rv    = proset#load#load(s:storage, s:settings, a:path, a:init_phase)
    let l:ret   = l:rv.result

    if l:ret == 0
        let s:settings      = l:rv.settings
        let s:configuration = l:rv.configuration
    endif

    return l:ret
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
    return s:load(a:path, 0)
endfunction

function! ProsetReload()
    return ProsetLoad(".")
endfunction

function! ProsetClose()
    let l:rv            = proset#close#close(s:settings)
    let s:settings      = l:rv.settings
    let s:configuration = l:rv.configuration
endfunction

function! ProsetCreate(settings_name, path, ...)
    call proset#create#create(s:storage, a:settings_name, a:path, a:000)
endfunction

augroup Proset
    autocmd!

    try
        call s:validate_settings_file()

        autocmd VimEnter * call proset#enable#enable(s:settings)
        autocmd VimLeave * call proset#enable#disable(s:settings)

        if exists('#User#ProsetRegisterInternalSettingsEvent')
            doautocmd User ProsetRegisterInternalSettingsEvent
        endif

        if exists('#User#ProsetRegisterSettingsEvent')
            doautocmd User ProsetRegisterSettingsEvent
        endif

        call s:load(".", 1)

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
