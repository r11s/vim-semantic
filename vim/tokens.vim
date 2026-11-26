" Meldet fuer jede Stelle der Datei die Vim-Highlight-Gruppe.
" Ausgabe je Abschnitt: Zeile, Spalte, Laenge (UTF-16, wie in VS Code), Gruppe
set nomodeline noswapfile
set encoding=utf-8 fileencodings=utf-8 fileformats=unix,dos
let &runtimepath = $VIMRUNTIME
let &background = $VH_BACKGROUND
" Wie gVim alle Farben verwenden. Sonst waehlen manche Schemata den Zweig fuer
" farbarme Terminals und loesen dabei Verknuepfungen zwischen Gruppen auf.
set t_Co=256
if has('termguicolors')
  set termguicolors
endif
" Wie defaults.vim: Zahlen und Zeichenketten in C-artigen Kommentaren faerben
let c_comment_strings = 1
" Wie gVim die Dateityp-Plugins laden: sie legen u. a. fest, was ein Wort ist, und
" davon haengt die Faerbung ab. Externe Programme duerfen sie dabei nicht starten.
let g:plugin_exec = 0
filetype plugin on
syntax on
execute 'colorscheme ' . $VH_SCHEME
execute 'edit ' . fnameescape($VH_IN)
if &filetype ==# '' && $VH_FILETYPE !=# ''
  let &filetype = $VH_FILETYPE
endif
syntax sync fromstart

let s:out = []
for s:lnum in range(1, line('$'))
  let s:byte = 1
  let s:col = 0
  let s:start = 0
  let s:group = ''
  for s:char in split(getline(s:lnum), '\zs')
    let s:name = synIDattr(synIDtrans(synID(s:lnum, s:byte, 1)), 'name')
    if s:name !=# s:group
      if s:group !=# ''
        call add(s:out, join([s:lnum - 1, s:start, s:col - s:start, s:group], "\t"))
      endif
      let s:group = s:name
      let s:start = s:col
    endif
    let s:byte += strlen(s:char)
    for s:code in str2list(s:char, 1)
      let s:col += s:code >= 0x10000 ? 2 : 1
    endfor
  endfor
  if s:group !=# ''
    call add(s:out, join([s:lnum - 1, s:start, s:col - s:start, s:group], "\t"))
  endif
endfor
call writefile(s:out, $VH_OUT)
qall!
