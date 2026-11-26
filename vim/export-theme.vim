" Liest alle Gruppen mit eigenen Farben/Stilen aus dem Colorscheme.
set nomodeline noswapfile encoding=utf-8
let &runtimepath = $VIMRUNTIME
let &background = $VH_BACKGROUND
" Wie gVim alle Farben verwenden. Sonst waehlen manche Schemata den Zweig fuer
" farbarme Terminals und loesen dabei Verknuepfungen zwischen Gruppen auf.
set t_Co=256
if has('termguicolors')
  set termguicolors
endif
filetype on
syntax on
execute 'colorscheme ' . $VH_SCHEME
" Syntaxdateien laden, damit auch ihre eigenen Gruppen bekannt sind
for s:ft in split($VH_FILETYPES, ',')
  enew!
  " Meldungen einzelner Syntaxdateien sollen den Export nicht abbrechen
  silent! let &l:filetype = s:ft
endfor
runtime colors/lists/default.vim

function! s:Color(value, fallback) abort
  if a:value ==# '' || a:value ==? 'NONE'
    return ''
  elseif a:value =~# '^#'
    return a:value
  elseif a:value ==? 'fg' || a:value ==? 'foreground'
    return s:fg
  elseif a:value ==? 'bg' || a:value ==? 'background'
    return s:bg
  endif
  return get(v:colornames, tolower(a:value), a:fallback)
endfunction

let s:dark = &background ==# 'dark'
let s:fg = s:dark ? '#ffffff' : '#000000'
let s:bg = s:dark ? '#000000' : '#ffffff'
let s:normal = get(hlget('Normal'), 0, {})
let s:fg = s:Color(get(s:normal, 'guifg', ''), s:fg)
let s:fg = s:fg ==# '' ? (s:dark ? '#ffffff' : '#000000') : s:fg
let s:bg = s:Color(get(s:normal, 'guibg', ''), s:bg)
let s:bg = s:bg ==# '' ? (s:dark ? '#000000' : '#ffffff') : s:bg

let s:groups = {}
for s:hl in hlget()
  if has_key(s:hl, 'linksto') || get(s:hl, 'cleared', v:false)
    continue
  endif
  let s:groups[s:hl.name] = {
        \ 'foreground': s:Color(get(s:hl, 'guifg', ''), ''),
        \ 'background': s:Color(get(s:hl, 'guibg', ''), ''),
        \ 'attributes': keys(get(s:hl, 'gui', {}))}
endfor
call writefile([json_encode({'type': &background, 'foreground': s:fg, 'background': s:bg, 'groups': s:groups})], $VH_OUT)
qall!
