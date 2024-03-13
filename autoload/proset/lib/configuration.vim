if exists("g:autoloaded_proset_lib_configuration")
    finish
endif
let g:autoloaded_proset_lib_configuration = 1

let s:configuration_storage = {'data': {}}

function! s:configuration_storage.create(data)
    let l:ret = deepcopy(self)
    let l:ret.data = a:data
    return l:ret
endfunction

function! s:configuration_storage.get(parameter, default_value)
    if has_key(self.data, a:parameter)
        return self.data[a:parameter]
    endif
    return a:default_value
endfunction

function! s:get_error_message(file, reason)
    return "proset:parse-configuration:" . a:file . ":" . a:reason
endfunction

function! proset#lib#configuration#parse_file(file, separator)
    if !filereadable(a:file)
        return s:configuration_storage.create({})
    endif

    let l:ret = {}
    for l:row in readfile(a:file)
        let l:row = trim(l:row)

        if empty(l:row) || l:row[0] == "#"
            continue
        endif

        let l:kv = split(l:row, a:separator, 1)

        if len(l:kv) < 2
            throw s:get_error_message(a:file, 'has no separator')
        endif

        let l:key = trim(l:kv[0])
        if empty(l:key)
            throw s:get_error_message(a:file, 'has empty key')
        endif

        let l:val = trim(join(l:kv[1:], a:separator))
        let l:ret[l:key] = l:val
    endfor

    return s:configuration_storage.create(l:ret)
endfunction
