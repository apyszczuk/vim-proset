if exists("g:autoloaded_proset_load")
    finish
endif
let g:autoloaded_proset_load = 1

let s:settings_tmp = {}

function! s:get_error_number_and_message(error_number, message)
    return a:error_number . "|" . a:message
endfunction

function! proset#load#load(storage, settings, path, init_phase)
    let l:cwd_orig = getcwd()

    try
        try
            let l:settings_file = a:path . "/" . g:proset_settings_file

            if !filereadable(l:settings_file)
                if a:init_phase == 0
                    let l:msg = "Configuration file is missing"
                    throw s:get_error_number_and_message(20, l:msg)
                endif

                return { "result": 1, "settings": {}, "configuration": {} }
            endif

            let l:cfg = json_decode(join(readfile(l:settings_file), "\n"))
            let l:name = proset#lib#dict#get(l:cfg, "", "proset_settings")

            if empty(l:name)
                let l:msg = "'proset_settings' is empty or missing"
                throw s:get_error_number_and_message(21, l:msg)
            endif

            if !has_key(a:storage, l:name)
                let l:msg = l:name . " is not supported"
                throw s:get_error_number_and_message(30, l:msg)
            endif

            noautocmd call chdir(a:path)
            let Constructor     = function(a:storage[l:name])
            let s:settings_tmp  = Constructor(l:cfg, {"mode": "load"})

            " This is important becuase calling disable on Settings Object
            " expects to be in project root path, yet it was switched due to
            " construction of Settings Object above
            noautocmd call chdir(l:cwd_orig)
            call proset#enable#disable(a:settings)

            " And go back to project root path of loaded project
            noautocmd call chdir(a:path)

            if a:init_phase == 0
                call proset#enable#enable(s:settings_tmp)
                :redraw!
                call proset#print#print_info(s:settings_tmp.get_settings_name(),
                \       s:settings_tmp.get_project_name() . " was loaded")
            else
                autocmd VimEnter *
                \ :redraw! |
                \ call proset#print#print_info(s:settings_tmp.get_settings_name(),
                \       s:settings_tmp.get_project_name() . " was loaded")
            endif

            if exists('#User#ProsetSettingsChosenEvent')
                doautocmd User ProsetSettingsChosenEvent
            endif

            if len(autocmd_get(#{group: 'Proset', event: 'DirChangedPre'})) == 0
                autocmd Proset DirChangedPre * :call ProsetClose()
            endif

            return
            \ {
            \   "result"        : 0,
            \   "settings"      : deepcopy(s:settings_tmp),
            \   "configuration" : deepcopy(l:cfg)
            \ }

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

        return { "result": s:data[0], "settings": {}, "configuration": {} }
    endtry
endfunction
