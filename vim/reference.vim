" Soll-Werte fuer die Messung: so, wie gVim mit defaults.vim jedes Zeichen zeigt.
" Bewusst unabhaengig von tokens.vim geschrieben.
" Ausgabe: Zeile, Spalte, Laenge (UTF-16), Gruppe, fg, bg, Stil
set nomodeline noswapfile
set encoding=utf-8 fileencodings=utf-8 fileformats=unix,dos
let &runtimepath = $VIMRUNTIME
let &background = $VH_BACKGROUND
set t_Co=256
if has('termguicolors')
  " silent!: vim.exe unter Windows lehnt das ohne Konsole ab (E954)
  silent! set termguicolors
endif
let c_comment_strings = 1
filetype plugin indent on
syntax on
execute 'colorscheme ' . $VH_SCHEME
execute 'edit ' . fnameescape($VH_IN)
syntax sync fromstart
runtime colors/lists/default.vim

function! s:Hex(value) abort
  if a:value ==# '' || a:value =~# '^#'
    return tolower(a:value)
  endif
  return tolower(get(v:colornames, tolower(a:value), a:value))
endfunction

" Aussehen einer Gruppen-ID; ohne eigene Farbe gilt Normal
let s:normal = synIDtrans(hlID('Normal'))
let s:dark = &background ==# 'dark'
let s:fg = s:Hex(synIDattr(s:normal, 'fg#', 'gui'))
let s:bg = s:Hex(synIDattr(s:normal, 'bg#', 'gui'))
let s:fg = s:fg =~# '^#' ? s:fg : (s:dark ? '#ffffff' : '#000000')
let s:bg = s:bg =~# '^#' ? s:bg : (s:dark ? '#000000' : '#ffffff')

function! s:Resolve(value, fallback) abort
  if a:value ==? 'fg' || a:value ==? 'foreground'
    return s:fg
  elseif a:value ==? 'bg' || a:value ==? 'background'
    return s:bg
  endif
  let l:hex = s:Hex(a:value)
  return l:hex =~# '^#' ? l:hex : a:fallback
endfunction

let s:cache = {}
function! s:Look(id) abort
  if !has_key(s:cache, a:id)
    let l:t = synIDtrans(a:id)
    let l:fg = s:Resolve(synIDattr(l:t, 'fg#', 'gui'), s:fg)
    let l:bg = s:Resolve(synIDattr(l:t, 'bg#', 'gui'), s:bg)
    if synIDattr(l:t, 'reverse', 'gui') ==# '1' || synIDattr(l:t, 'inverse', 'gui') ==# '1'
      let [l:fg, l:bg] = [l:bg, l:fg]
    endif
    let l:style = (synIDattr(l:t, 'bold', 'gui') ==# '1' ? 'b' : '')
          \ . (synIDattr(l:t, 'italic', 'gui') ==# '1' ? 'i' : '')
          \ . (synIDattr(l:t, 'underline', 'gui') ==# '1' || synIDattr(l:t, 'undercurl', 'gui') ==# '1' ? 'u' : '')
          \ . (synIDattr(l:t, 'strikethrough', 'gui') ==# '1' ? 's' : '')
    let l:name = synIDattr(l:t, 'name')
    let s:cache[a:id] = join([l:name ==# '' ? '-' : l:name, l:fg, l:bg, l:style], "\t")
  endif
  return s:cache[a:id]
endfunction

let s:out = [join(['#', s:fg, s:bg], "\t")]
for s:lnum in range(1, line('$'))
  let s:byte = 1
  let s:col = 0
  for s:char in split(getline(s:lnum), '\zs')
    let s:width = 0
    for s:code in str2list(s:char, 1)
      let s:width += s:code >= 0x10000 ? 2 : 1
    endfor
    let s:id = synID(s:lnum, s:byte, 1)
    let s:look = s:id == 0 ? join(['-', s:fg, s:bg, ''], "\t") : s:Look(s:id)
    call add(s:out, join([s:lnum - 1, s:col, s:width], "\t") . "\t" . s:look)
    let s:byte += strlen(s:char)
    let s:col += s:width
  endfor
endfor
call writefile(s:out, $VH_OUT)
qall!
