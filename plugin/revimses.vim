scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_revimses')
  finish
endif
let g:loaded_revimses = 1

let s:true = 1
let s:false = 0

" Option Vals
if !exists('g:revimses#session_dir')
  let g:revimses#session_dir = $HOME.'/.vimsessions'
endif

if !exists('revimses#sessionoptions')
  let revimses#sessionoptions = 'buffers,curdir,help,tabpages,winsize,slash'
endif

let g:revimses#session_dir = fnamemodify(expand(g:revimses#session_dir), 'p')

let g:revimses#_save_session_flag = s:true " TabMerge, ClearSession時用のフラグ
let g:revimses#_win_file = g:revimses#session_dir . '/.winpos.vim'

if !isdirectory(revimses#session_dir)
  call mkdir(revimses#session_dir,'p')
endif

augroup Revimses
  autocmd!
  " autocmd GUIEnter * call revimses#load_window(revimses#_win_file)
  " nestedしないとSyntaxなどの設定が繁栄されない（BufReadとかがたぶん呼ばれない）
  " autocmd VimEnter * nested if argc() == 0 && bufnr('$') == 1 | call revimses#restore_on_startup() | endif
  autocmd VimLeavePre * call revimses#save_window(revimses#_win_file)
  autocmd VimLeavePre * if revimses#check_savable() | call revimses#save_session(".default.vim", s:true) | endif
augroup END

command! -nargs=? -complete=customlist,revimses#customlist
      \ Revimses call revimses#load_window(g:revimses#_win_file) | call revimses#load_session(<q-args>, s:true)
command! -nargs=1 -complete=customlist,revimses#customlist
      \ RevimsesDelete call revimses#delete_session(<q-args>, s:true)
command! -nargs=1
      \ RevimsesSave call revimses#save_session(<q-args>, s:true)
command!
      \ RevimsesClearAndQuit call revimses#clear_session()


if has('job') || has('nvim')
  fun! revimses#timer_callback(timer) abort
    call revimses#save_session('.swap.vim', s:false)
  endf

  call timer_start(5 * 60 * 1000, 'revimses#timer_callback', {'repeat' : -1})
else
  augroup revimeses
    autocmd!
    autocmd CursorHold,CursorHoldI * call revimses#save_session('.swap.vim',s:false)
  augroup END
endif

let &cpo = s:save_cpo
unlet s:save_cpo
