if exists("g:autoloaded_proset_create")
    finish
endif
let g:autoloaded_proset_create = 1

function! s:remove_slashes(str)
    let l:str = a:str
    while len(l:str) > 0 && strpart(l:str, len(l:str)-1, 1) == "/"
        let l:str = strpart(l:str, 0, len(l:str)-1)
    endwhile
    return l:str
endfunction

function! proset#create#create(storage, settings_name, path, fargs)
    let l:path = s:remove_slashes(simplify(fnamemodify(trim(a:path), ":p")))
    try
        if !has_key(a:storage, a:settings_name)
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

        let Constructor             = function(a:storage[a:settings_name])
        let l:settings_tmp          = Constructor({}, {"mode": "create"})

        let l:rv = l:settings_tmp.create(l:path, a:fargs)
        let l:rv.dictionary.proset_settings = a:settings_name

        let Encoder     = function(g:proset_json_encoder.function)
        let l:string    = Encoder(l:rv.dictionary, g:proset_json_encoder.options)
        let l:content   = split(l:string, "\n")

        call writefile(l:content, l:settings_file)

        call proset#print#print_info(a:settings_name,
        \       l:rv.project_name . " was created at " . l:path)
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
