"=======================================================================================================================
" File: plugin/layout.vim
" Description: vim buffer layout expand and switch
" Author: hanson <liangguohaun@gmail.com>
" Github: https://github.com/liangguohaun
" Last Modified: 2016-11-11 17:28
"=======================================================================================================================

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => common functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! layout#exe(str) abort
    if g:layout#debug
        echo a:str
        return
    endif
    exe a:str
endfunction

function! layout#getlist(info) abort
    redir => bufoutput
    if a:info == 1
        silent buffers
    else
        silent buffers!
    endif
    redir END
    return bufoutput
endfunction

function! layout#getbufnr() abort
    let s:bufoutput = layout#getlist(1)
    let s:arrlist = []
    for buf in split(s:bufoutput, '\n')
        let s:bits = split(buf, ' ')
        call add(s:arrlist, str2nr(s:bits[0]))
    endfor
    return s:arrlist
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" =>vim layout expand more nature
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! layout#expand(col, ...)
    " let expr = printf('%d/%d.0', a:row, a:col)
    " let trow = eval(expr)

    let l:arrlist = layout#getbufnr()

    call layout#exe( 'only' )

    let index = 0
    while index < len(l:arrlist)
        let item = l:arrlist[index]
        if index == 0
            call layout#exe( 'rightbelow vsp ' . bufname(item) )
            call layout#exe( "normal \<c-w>\<c-w>" )
            call layout#exe( 'q' )
        elseif index < a:col
            call layout#exe( 'rightbelow vsp ' . bufname(item) )
        else
            if index % a:col == 0
                call layout#exe( "normal " . (a:col - 1) . "\<c-w>h" )
            else
                call layout#exe( "normal \<c-w>l" )
            endif
            call layout#exe( 'rightbelow sp ' . bufname(item) )
        endif
        let index = index + 1
        " num limit
        if a:0 > 0 && a:1 < index + 1 | break | endif
    endwhile
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim layout switch like tmux
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! layout#switch(tag) abort
    let winnr = winnr('$')
    let buflistinfo = []

    " restore the buflistinfo
    for i in range(1, winnr)
        let bufnr = winbufnr(i)
        let bufname = bufname(bufnr)
        call add(buflistinfo, [bufnr, bufname])
    endfor

    " close all winbuf and restore the buflistinfo
    for x in buflistinfo
        let bufnr = x[0]
        call layout#exe( printf('bd! %d', bufnr) )
    endfor

    " reopen winbuf with specail layout
    if a:tag == 1
        for x in buflistinfo
            let bufname = x[1]
            let action = 'e'
            if index(buflistinfo, x) > 0 | let action = 'sp' | endif
            call layout#exe( printf('botright %s %s', action, bufname) )
        endfor
    elseif a:tag == 2
        for x in buflistinfo
            let bufname = x[1]
            let action = 'e'
            if index(buflistinfo, x) > 0 | let action = 'vsp' | endif
            call layout#exe( printf('rightbelow %s %s', action, bufname) )
        endfor
    else
        call layout#expand(buflistinfo)
    endif
endfunction

function! layout#expand(buflist, ...) abort
    " empty list do nothing
    if len(a:buflist) == 0 | return | endif
    " mail code
    let len = len(g:layout#default)
    let currlist = a:buflist[0:len-1]
    let buflistnext = a:buflist[len: len*2-1]
    for buf in currlist
        let bufnr = buf[0]
        let bufname = buf[1]
        let index = index(currlist, buf)
        let layout = g:layout#default[index]
        let action = s:layout_dict[layout]
        call layout#exe( printf('%s %s', action, bufname) )
        if index == 0 && a:0 == 0 | call layout#exe('only') | endif
    endfor
    " recusive
    call layout#expand(buflistnext, 1)
endfunction

function! layout#chunk(list, count) abort
    let len = len(a:list)
    let l = []
    let chunk = []
    for i in range(1, len)
        call add(chunk, a:list[i-1])
        if i % a:count == 0
            call add(l, chunk)
            let chunk = []
        endif
    endfor
    " add the rest of list
    if len(chunk) != 0 | call add(l, chunk) | endif
    return l
endfunction

function! layout#autoswitch() abort
    let s:layout_autoswitch = exists('s:layout_autoswitch') ? ( s:layout_autoswitch == 3 ? 1 : s:layout_autoswitch + 1 ) : 3
    call layout#switch(s:layout_autoswitch)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => window swap
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! layout#swap() abort
    " init
    if !exists('s:restore_win_info_swap')
        let s:restore_win_info_swap = []
    endif

    " restore wininfo
    let winnr = winnr()
    let bufnr = winbufnr(winnr)
    let bufname = bufname(bufnr)
    call add(s:restore_win_info_swap, [winnr, bufnr, bufname])
    " swap window
    if (len(s:restore_win_info_swap) == 2)
        if s:restore_win_info_swap[0] == s:restore_win_info_swap[1]
            let s:restore_win_info_swap = s:restore_win_info_swap[0:0]
        else
            let winnr1   = s:restore_win_info_swap[0][0]
            let bufname1 = s:restore_win_info_swap[0][2]
            let winnr2   = s:restore_win_info_swap[1][0]
            let bufname2 = s:restore_win_info_swap[1][2]
            exe printf('e %s', bufname1)
            exe printf('%dwincmd w', winnr1)
            exe printf('e %s', bufname2)
            exe printf('%dwincmd w', winnr2)
            " clear restore wininfo
            unlet s:restore_win_info_swap
        endif
    endif
    if exists('s:restore_win_info_swap') && len(s:restore_win_info_swap) == 1
        echo printf( "waiting for swap [%d] %s", s:restore_win_info_swap[0][0], s:restore_win_info_swap[0][2] )
    endif

endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:layout_dict = {1:'botright sp', 2:'rightbelow sp', 3:'rightbelow vsp', 4:'botright vsp'}
let g:layout#default = [1,2,3]
let g:layout#debug = 0

cabbrev lbe LayoutBufferExpand
cabbrev lbs LayoutBufferSwitch
nnoremap <silent> <Plug>(layout-autoswitch) :<C-u>call layout#autoswitch()<Return>
nnoremap <silent> <Plug>(layout-swap) :<C-u>call layout#swap()<Return>
nmap <C-w><Space> <Plug>(layout-autoswitch)
nmap <C-w>m       <Plug>(layout-swap)

command! -nargs=+ LayoutBufferExpand call layout#expand(<f-args>)
command! -nargs=+ LayoutBufferSwitch call layout#switch(<f-args>)


" vim: fdm=marker ts=4 sw=4 sts=4 expandtab
