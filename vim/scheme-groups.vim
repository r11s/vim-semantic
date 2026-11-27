" Wie jedes Farbschema die Gruppen eines Dateityps zuordnet. Manche Schemata geben
" z. B. cString eine andere Gruppe als das Standardschema.
let &runtimepath = $VIMRUNTIME
set t_Co=256
if has('termguicolors')
  silent! set termguicolors
endif
let c_comment_strings = 1
let g:plugin_exec = 0
filetype plugin on
syntax on
let s:groups = split($VH_GROUPS, ',')
let s:out = {}
for [s:scheme, s:background] in map(split($VH_SCHEMES, ','), 'split(v:val)')
  let &background = s:background
  execute 'colorscheme ' . s:scheme
  enew!
  " Bei manchen Typen haengen die Regeln vom Inhalt ab (sh: erste Zeile "#!...")
  if $VH_SAMPLE != ''
    call setline(1, readfile($VH_SAMPLE))
  endif
  let &filetype = $VH_FILETYPE
  let s:map = {}
  for s:group in s:groups
    let s:map[s:group] = synIDattr(synIDtrans(hlID(s:group)), 'name')
  endfor
  let s:out[s:scheme . ' ' . s:background] = s:map
  bwipeout!
endfor
call writefile([json_encode(s:out)], $VH_OUT)
qall!
