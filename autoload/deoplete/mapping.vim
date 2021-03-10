"=============================================================================
" FILE: mapping.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
" License: MIT license
"=============================================================================

function! deoplete#mapping#_init() abort
  " Note: The dummy function is needed for cpoptions bug in neovim
  inoremap <expr><silent> <Plug>_
        \ deoplete#mapping#_dummy('deoplete#mapping#_complete')
  inoremap <expr><silent> <Plug>+
        \ deoplete#mapping#_dummy('deoplete#mapping#_prev_complete')

  " Note: The dummy mappings may be inserted on other modes.
  cnoremap <silent> <Plug>_  <Nop>
  cnoremap <silent> <Plug>+  <Nop>
  noremap  <silent> <Plug>_  <Nop>
  noremap  <silent> <Plug>+  <Nop>
endfunction
function! deoplete#mapping#_dummy(func) abort
  return "\<C-r>=".a:func."()\<CR>"
endfunction
function! s:check_completion_info(candidates) abort
  if !exists('*complete_info')
    return 0
  endif

  let info = complete_info()
  let noinsert = &completeopt =~# 'noinsert'
  if (info.mode !=# '' && info.mode !=# 'eval')
        \ || (noinsert && info.selected > 0)
        \ || (!noinsert && info.selected >= 0)
        \ || !has_key(g:deoplete#_context, 'complete_position')
    return 1
  endif

  let input = getline('.')[: g:deoplete#_context.complete_position - 1]
  if deoplete#util#check_eskk_phase_henkan()
        \ && matchstr(input, '.$') =~# '[\u3040-\u304A]$'
    return 0
  endif
  return 0

  let old_candidates = sort(map(copy(info.items), 'v:val.word'))
  return sort(map(copy(a:candidates), 'v:val.word')) ==# old_candidates
endfunction
function! deoplete#mapping#_can_complete() abort
  return has_key(get(g:, 'deoplete#_context', {}), 'candidates')
        \ && !s:check_completion_info(g:deoplete#_context.candidates)
        \ && &modifiable
endfunction
function! deoplete#mapping#_complete() abort
  if !deoplete#mapping#_can_complete()
    let g:deoplete#_context.candidates = []
    return ''
  endif

  let auto_popup = deoplete#custom#_get_option(
        \ 'auto_complete_popup') !=# 'manual'

  if auto_popup
    " Note: completeopt must be changed before complete()
    call deoplete#mapping#_set_completeopt(g:deoplete#_context.is_async)
  endif

  " echomsg string(g:deoplete#_context)
  if empty(g:deoplete#_context.candidates) && deoplete#util#check_popup()
    " Note: call complete() to close the popup
    call complete(1, [])
    return ''
  endif

  call complete(g:deoplete#_context.complete_position + 1,
        \ g:deoplete#_context.candidates)

  return ''
endfunction
function! deoplete#mapping#_prev_complete() abort
  if s:check_completion_info(g:deoplete#_filtered_prev.candidates)
    return ''
  endif

  call deoplete#mapping#_set_completeopt(v:false)

  call complete(g:deoplete#_filtered_prev.complete_position + 1,
        \ g:deoplete#_filtered_prev.candidates)

  return ''
endfunction
function! deoplete#mapping#_set_completeopt(is_async) abort
  if !exists('g:deoplete#_saved_completeopt')
    let g:deoplete#_saved_completeopt = &completeopt
  endif
  set completeopt-=longest
  set completeopt+=menuone
  set completeopt-=menu
  if &completeopt !~# 'noinsert\|noselect' || a:is_async
    " Note: If is_async, noselect is needed to prevent without confirmation
    " problem
    set completeopt-=noinsert
    set completeopt+=noselect
  endif
endfunction
function! deoplete#mapping#_restore_completeopt() abort
  if exists('g:deoplete#_saved_completeopt')
    let &completeopt = g:deoplete#_saved_completeopt
    unlet g:deoplete#_saved_completeopt
  endif
endfunction
function! deoplete#mapping#_rpcrequest_wrapper(sources) abort
  return deoplete#util#rpcnotify(
        \ 'deoplete_manual_completion_begin',
        \ {
        \  'event': 'Manual',
        \  'sources': deoplete#util#convert2list(a:sources)
        \ })
endfunction
function! deoplete#mapping#_undo_completion() abort
  if empty(v:completed_item)
    return ''
  endif

  let input = deoplete#util#get_input('')
  if strridx(input, v:completed_item.word) !=
        \ len(input) - len(v:completed_item.word)
    return ''
  endif

  return repeat("\<C-h>", strchars(v:completed_item.word))
endfunction
function! deoplete#mapping#_complete_common_string() abort
  if !deoplete#is_enabled()
    return ''
  endif

  " Get cursor word.
  let prev = g:deoplete#_prev_completion
  if empty(prev)
    return ''
  endif

  let complete_str = prev.input[prev.complete_position :]
  let candidates = filter(copy(prev.candidates),
        \ 'stridx(tolower(v:val.word), tolower(complete_str)) == 0')

  if empty(candidates) || complete_str ==# ''
    return ''
  endif

  let common_str = candidates[0].word
  for candidate in candidates[1:]
    while stridx(tolower(candidate.word), tolower(common_str)) != 0
      let common_str = common_str[: -2]
    endwhile
  endfor

  if common_str ==# '' || complete_str ==? common_str
    return ''
  endif

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", strchars(complete_str)) . common_str
endfunction
function! deoplete#mapping#_insert_candidate(number) abort
  let prev = g:deoplete#_prev_completion
  let candidates = get(prev, 'candidates', [])
  let word = get(candidates, a:number, {'word': ''}).word
  if word ==# ''
    return ''
  endif

  " Get cursor word.
  let complete_str = prev.input[prev.complete_position :]
  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", strchars(complete_str)) . word
endfunction
