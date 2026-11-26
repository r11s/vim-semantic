" Gegenprobe: faerbt VH_IN nur mit den gesammelten Daten (Skript VH_RULES),
" ohne Dateityp-Erkennung und ohne Syntaxdateien. Ausgabe wie tokens.vim.
set nomodeline noswapfile
set encoding=utf-8 fileencodings=utf-8 fileformats=unix,dos
let &runtimepath = $VIMRUNTIME
set background=light
set t_Co=256
if has('termguicolors')
  set termguicolors
endif
colorscheme default
execute 'noautocmd edit ' . fnameescape($VH_IN)
" Einzelne Befehle duerfen scheitern; was dadurch fehlt, zeigt der Vergleich
execute 'silent! source ' . fnameescape($VH_RULES)
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
