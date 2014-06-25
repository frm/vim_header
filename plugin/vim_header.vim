ruby_file vim_header.rb

function! s:VimHeader(...)
    if a:0 == 0
        let s:name = @%
        let s:ft = &ft
    else
        let s:name = a:1
        let s:ft = matchstr(name, '/.*\.c/')
    endif

    if ft != ".c" || empty(ft)
        echoerr "Wrong file extension"
    else
        ruby << EOF
            puts name
        EOF
    endif

endfunction


command! -nargs=1 VimHeader call s:VimHeader(<f-args>)
