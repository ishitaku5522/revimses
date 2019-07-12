scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:true = 1
let s:false = 0

function! s:fullpath_sessiondir() abort
  return fnamemodify(expand(g:revimses#session_dir), 'p')
endfunction

function! revimses#load_window(window_file) abort
  if has('gui_running')
    if filereadable(expand(a:window_file))
      execute 'source' a:window_file
    endif
  endif
endfunction

function! revimses#restore_on_startup() abort
  let l:fullpath = s:fullpath_sessiondir() . '/.default.vim'
  if filereadable(l:fullpath)
    " let l:restore = confirm('Restore last session?',"&Yes\n&No")
    " if l:restore == 2
    "   return
    " endif
    call revimses#load_session(".default.vim",s:false)
  endif
endfunction

function! revimses#load_session(session_name, notify_flag) abort
  if a:session_name ==# ''
    let l:session_name = '.default.vim'
  else
    let l:session_name = a:session_name
  endif

  " let revimses#session_loaded = s:true
  let l:fullpath = s:fullpath_sessiondir() . '/' . l:session_name
  if filereadable(l:fullpath)
    silent execute 'source' l:fullpath
    if a:notify_flag == s:true
      echom "Session-file: '" . l:fullpath . "' was loaded."
    endif
    if l:session_name ==# '.default.vim'
      call rename(l:fullpath, s:fullpath_sessiondir() . '/.swap.vim')
    endif
  else
    if a:notify_flag == s:true
      echoerr "Session-file: '" . l:fullpath . "' can't be found."
    endif
  endif
endfunction

function! revimses#save_session(session_name,notify_flag) abort
  if g:revimses#_save_session_flag == s:false
    return
  endif

  let l:saved_sessionopts = &sessionoptions
  let &sessionoptions = g:revimses#sessionoptions
  let session_dir = s:fullpath_sessiondir()
  try
    execute  'mksession! '  session_dir . '/' . a:session_name
    call setfperm(session_dir . '/' . a:session_name, 'rw-rw-rw-')
    if a:notify_flag == s:true
      echom "Session saved to '" . session_dir . '/' . a:session_name . "'."
    endif
    if a:session_name ==# '.default.vim'
      call delete(session_dir . '/' . '.swap.vim')
    endif
  catch
    echoerr v:exception
  finally
    let &sessionoptions = l:saved_sessionopts
  endtry
endfunction

function! revimses#delete_session(session_name,notify_flag) abort
  let l:delete_flag = confirm('Really delete session file? :' . a:session_name, "&Yes\n&No",2)
  if l:delete_flag == 1
    call delete(s:fullpath_sessiondir() . '/' . a:session_name)
    echom "Session-file: '" . s:fullpath_sessiondir() . '/' . a:session_name . "' was deleted."
  endif
endfunction

function! revimses#save_window(save_window_file) abort
  let options = [
        \ 'set lines=' . &lines,
        \ 'set columns=' . &columns,
        \ 'winpos ' . getwinposx() . ' ' . getwinposy(),
        \ ]

  if has('win32') && libcallnr('User32.dll', 'IsZoomed', v:windowid)
    let window_maximaize = [
          \ 'if has("vim_starting")',
          \ '  au GUIEnter * simalt ~x',
          \ 'else',
          \ '  simalt ~x',
          \ 'endif',
          \ ]
    call extend(options, window_maximaize)
  endif

  call writefile(options, a:save_window_file)
  call setfperm(a:save_window_file, 'rw-rw-rw-')
endfunction

function! revimses#clear_session() abort
  call g:revimses#save_session('.default.vim',s:false)
  call rename(s:fullpath_sessiondir() . '/.default.vim',
        \ s:fullpath_sessiondir() . '/.lastcleared.vim')
  let g:revimses#_save_session_flag = s:false
  quitall
endfunction

function! revimses#customlist(ArgLead, CmdLine, CursorPos) abort
  let l:save_cd = getcwd()
  exe 'cd ' . s:fullpath_sessiondir()
  let l:filelist = glob(a:ArgLead . '*',1,1)
  exe 'cd ' . expand(l:save_cd)
  return l:filelist
endfunction

function! revimses#check_restoreable() abort
  if argc() == 0 && tabpagenr('$') == 1 && winnr('$') == 1 && bufname('%') ==# ''
    return 1
  else
    return 0
  endif
endfunction

function! revimses#check_savable() abort
  if tabpagenr('$') == 1 && winnr('$') == 1 && bufname('%') ==# ''
    return 0
  endif

  if g:revimses#_save_session_flag
    return 1
  else
    return 0
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
