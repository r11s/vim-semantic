" Sammelt, womit Vim die Datei VH_IN faerbt: Einstellungen, Gruppen und Regeln.
" Ist VH_IN leer, wird nur der Dateityp VH_FILETYPE ohne Inhalt geladen.
" Gleiche Einstellungen wie in tokens.vim.
set nomodeline noswapfile
set encoding=utf-8 fileencodings=utf-8 fileformats=unix,dos
let &runtimepath = $VIMRUNTIME
set background=light
set t_Co=256
if has('termguicolors')
  set termguicolors
endif
let c_comment_strings = 1
let g:plugin_exec = 0
filetype plugin on
syntax on
colorscheme default

" Zwischen den Marken schreibt das ergaenzte Vim (vim-synlog.patch) alle Befehle mit
function! s:mark(text)
  if $VH_SYNLOG !=# ''
    call writefile([a:text], $VH_SYNLOG, 'a')
  endif
endfunction

call s:mark('--start')
if $VH_IN !=# ''
  execute 'edit ' . fnameescape($VH_IN)
  if &filetype ==# '' && $VH_FILETYPE !=# ''
    let &filetype = $VH_FILETYPE
  endif
else
  enew
  let &filetype = $VH_FILETYPE
endif
syntax sync fromstart
call s:mark('--end')

let s:links = {}
for s:entry in hlget()
  let s:links[s:entry.name] = get(s:entry, 'linksto', '')
endfor
call writefile([json_encode(#{
      \ filetype: &filetype,
      \ version: v:versionlong,
      \ iskeyword: &iskeyword,
      \ syntaxIskeyword: trim(execute('syntax iskeyword')),
      \ links: s:links,
      \ list: split(execute('syntax list'), "\n"),
      \ })], $VH_OUT)
qall!
