if exists("g:autoloaded_proset_lib_json_encode")
    finish
endif
let g:autoloaded_proset_lib_json_encode = 1

function! s:keystring_aligned(key,
\           string,
\           key_column_start,
\           string_column_start)
    let l:key       = '"' . a:key . '":'
    let l:string    = a:string . ",\n"
    let l:count     = a:string_column_start-len(l:key)-a:key_column_start-1

    return l:key . repeat(" ", l:count) . l:string
endfunction

function! s:keyvalue_to_string(key,
\           value,
\           indent_width,
\           indent_level,
\           value_column_start)
    if type(a:value) == v:t_dict
        let l:ret  = '"' . a:key . '":' . "\n"
        let l:ret .= s:dictionary_to_string(a:value,
        \               a:indent_width,
        \               a:indent_level+1,
        \               a:value_column_start)
        return l:ret
    else
        if type(a:value) == v:t_list
            let l:string = substitute(json_encode(a:value), '","', '", "', "g")
        elseif type(a:value) == v:t_string
            let l:string = '"' . a:value . '"'
        endif

        return s:keystring_aligned(a:key,
        \           l:string,
        \           (a:indent_width*a:indent_level),
        \           a:value_column_start)
    endif
endfunction

function! s:indent(indent_width, indent_level)
    if a:indent_level < 1
        return ""
    endif

    return repeat(" ", a:indent_width*a:indent_level)
endfunction

function! s:dictionary_to_string(dictionary,
\           indent_width,
\           indent_level,
\           value_column_start)
    let l:ret = s:indent(a:indent_width, a:indent_level-1) . "{\n"

    let l:dkeys     = sort(keys(a:dictionary))
    let l:ps_key    = "proset_settings"
    if has_key(a:dictionary, l:ps_key)
        call remove(l:dkeys, index(l:dkeys, l:ps_key))
        call insert(l:dkeys, l:ps_key, 0)
    endif

    for l:key in l:dkeys
        let l:ret .= s:indent(a:indent_width, a:indent_level)
        let l:ret .= s:keyvalue_to_string(l:key,
        \               a:dictionary[l:key],
        \               a:indent_width,
        \               a:indent_level,
        \               a:value_column_start)
    endfor

    let l:ret .= s:indent(a:indent_width, a:indent_level-1) . "},\n"

    return l:ret
endfunction

function! s:remove_trailing_commas(json_str)
    let l:str   = trim(a:json_str)
    let l:index = len(l:str)-1

    if l:str[l:index] == ','
        let l:str = strcharpart(l:str, 0, l:index)
    endif

    function! s:sub(str)
        return "\n" . a:str . "}"
    endfunction

    return substitute(l:str, ',\n\( *\)}', '\=s:sub(submatch(1))', "g")
endfunction


function! proset#lib#json_encode#encode(dictionary, options)
    let l:str = s:dictionary_to_string(a:dictionary,
    \               a:options.indent_width,
    \               a:options.indent_init_level,
    \               a:options.value_column_start)
    return s:remove_trailing_commas(l:str)
endfunction
