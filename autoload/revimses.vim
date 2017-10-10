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

function! revimses#load_session(session_name,notify_flag) abort
  " let revimses#session_loaded = s:true
  let l:fullpath = s:fullpath_sessiondir() . '/' . a:session_name
  if filereadable(l:fullpath)
    execute 'source' l:fullpath
    if a:notify_flag == s:true
      echom "Session-file: '" . l:fullpath . "' was loaded."
    endif
    if a:session_name ==# '.default.vim'
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
  let l:window_maximaize = ''
  if has('win32')
    if libcallnr('User32.dll', 'IsZoomed', v:windowid)
      let l:window_maximaize = 'au GUIEnter * simalt ~x'
    endif
  endif
  let options = [
        \ 'set lines=' . &lines,
        \ 'set columns=' . &columns,
        \ 'winpos ' . getwinposx() . ' ' . getwinposy(),
        \ l:window_maximaize
        \ ]
  call writefile(options, a:save_window_file)
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

let &cpo = s:save_cpo
unlet s:save_cpo
