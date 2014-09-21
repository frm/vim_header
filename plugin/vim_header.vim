let s:path = expand('<sfile>:p:h')

function! s:VimHeader(...)
    if !a:0
        let l:name = @%
        let l:ft = &ft
    else
        let l:name = a:1
        let l:ft = matchstr(name, '.*\.c')
    endif

    if ft != "c" || empty(ft)
        echoerr "Wrong file extension"
        echoerr ft
    else
        let l:script = s:path . "/vim_header.rb " . name
        exec '!ruby ' . l:script
    endif

endfunction

silent command! -nargs=* VimHeader call s:VimHeader(<f-args>)