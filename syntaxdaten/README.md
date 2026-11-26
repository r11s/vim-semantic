# Syntaxdaten

Erzeugt mit `node werkzeuge/syntaxdaten.js`, Gegenprobe mit `node werkzeuge/syntaxdaten-pruefen.js`.
Nicht von Hand aendern. Abgeleitet aus den Syntaxdateien von Vim; Lizenzen in ../LIZENZEN.md.

Je Datei:

- `befehle`: alle ausgefuehrten `syntax`-Befehle in ihrer Reihenfolge, als [Herkunft, Befehl]
- `gruppen`: Gruppe und die Gruppe, auf die sie verweist (`null` = keine)
- `liste`: Ausgabe von `:syntax list` (nach Gruppen sortiert, ohne Reihenfolge und Gross/Klein)
- `iskeyword`, `syntaxIskeyword`: was als Wort gilt
- `inhaltsabhaengig`: die Regeln sind anders als bei einer leeren Datei desselben Typs

`name~testdatei.json`: gleicher Dateityp, aber andere Regeln als in `name.json`.
Ohne Testdatei, aus einer leeren Datei erzeugt und von der Gegenprobe nicht erfasst: json, html, css, markdown, yaml.
Zum Erzeugen ist ein Vim mit `werkzeuge/vim-synlog.patch` noetig.

| Datei | keyword | match | region | cluster | include | inhaltsabhaengig | Testdateien |
|---|--:|--:|--:|--:|--:|---|---|
| abap | 33 | 81 | 5 | 0 | 0 |  | 62_abap.abap |
| ada | 46 | 141 | 3 | 0 | 0 |  | 23_ada.adb |
| arduino | 146 | 31 | 8 | 0 | 0 |  | 80_processing.pde |
| asm | 1 | 45 | 3 | 0 | 0 |  | 18_assembly.asm |
| autohotkey | 12 | 17 | 2 | 1 | 0 |  | 79_autohotkey.ahk |
| awk | 26 | 29 | 5 | 0 | 0 |  | 58_awk.awk |
| basic | 11 | 184 | 9 | 5 | 0 |  | 100_basic.bas |
| c | 76 | 1 | 4 | 0 | 0 |  | 09_c.c |
| clojure | 11 | 35 | 9 | 3 | 0 |  | 44_clojure.clj |
| cobol | 46 | 46 | 0 | 12 | 0 |  | 39_cobol.cob |
| cpp | 105 | 31 | 8 | 0 | 0 |  | 07_cpp.cpp |
| cs | 6 | 71 | 46 | 1 | 1 |  | 06_csharp.cs |
| css | 123 | 178 | 23 | 0 | 0 |  |  |
| cuda | 130 | 31 | 8 | 0 | 0 |  | 50_cuda.cu |
| d | 232 | 39 | 24 | 13 | 0 |  | 51_d.d |
| dart | 14 | 8 | 3 | 0 | 0 |  | 19_dart.dart |
| dosbatch | 14 | 40 | 1 | 2 | 0 |  | 29_batch.bat |
| elm | 6 | 18 | 9 | 0 | 0 |  | 98_elm.elm |
| erlang | 35 | 55 | 11 | 1 | 0 |  | 48_erlang.erl |
| forth | 147 | 44 | 11 | 0 | 0 |  | 77_forth.fth |
| fortran | 59 | 103 | 4 | 1 | 0 | ja | 24_fortran.f90 |
| gdscript | 18 | 20 | 2 | 0 | 0 |  | 36_gdscript.gd |
| glsl | 665 | 11 | 8 | 0 | 0 |  | 47_glsl.glsl |
| go | 22 | 34 | 12 | 3 | 0 |  | 12_go.go |
| groovy | 519 | 294 | 125 | 8 | 6 |  | 32_groovy.groovy |
| haskell | 11 | 18 | 4 | 0 | 0 |  | 33_haskell.hs |
| html | 481 | 261 | 110 | 4 | 5 |  |  |
| java | 159 | 200 | 211 | 10 | 6 |  | 04_java.java |
| javascript | 19 | 12 | 6 | 1 | 0 |  | 02_javascript.js |
| json | 1 | 21 | 5 | 0 | 0 |  |  |
| julia | 1 | 95 | 59 | 26 | 0 |  | 29_julia.jl |
| kotlin | 42 | 29 | 6 | 0 | 0 |  | 16_kotlin.kt |
| lisp | 377 | 25 | 6 | 1 | 0 |  | 34_lisp.lisp, 57_emacslisp.el |
| lua | 24 | 130 | 14 | 0 | 0 |  | 22_lua.lua |
| markdown | 484 | 315 | 145 | 13 | 6 |  |  |
| matlab | 13 | 18 | 3 | 0 | 0 |  | 27_matlab.m |
| mojo | 53 | 24 | 6 | 0 | 0 |  | 86_mojo.mojo |
| nix | 8 | 39 | 18 | 1 | 0 |  | 27_nix.nix |
| nu | 3 | 647 | 8 | 0 | 0 |  | 82_nu.nu |
| objc | 266 | 130 | 10 | 5 | 0 |  | 20_objectivec.m |
| ocaml | 18 | 116 | 45 | 33 | 0 |  | 38_ocaml.ml |
| pascal | 115 | 7 | 6 | 0 | 0 |  | 28_delphi.pas |
| perl | 6 | 117 | 123 | 8 | 1 |  | 26_perl.pl |
| php | 718 | 318 | 141 | 11 | 6 |  | 10_php.php |
| progress | 179 | 13 | 9 | 1 | 0 |  | 95_openedge.p |
| prolog | 25 | 12 | 4 | 0 | 0 |  | 41_prolog.pl |
| ps1 | 21 | 52 | 10 | 2 | 0 |  | 14_powershell.ps1 |
| pyrex | 62 | 35 | 15 | 0 | 0 |  | 54_cython.pyx |
| python | 55 | 33 | 15 | 0 | 0 |  | 01_python.py |
| r | 12 | 114 | 15 | 0 | 0 |  | 11_r.R |
| racket | 303 | 73 | 11 | 7 | 0 |  | 83_racket.rkt |
| raku | 0 | 139 | 254 | 13 | 0 |  | 65_raku.raku |
| ruby | 1 | 149 | 176 | 36 | 0 |  | 17_ruby.rb |
| rust | 116 | 100 | 65 | 4 | 1 |  | 13_rust.rs |
| sas | 38 | 46 | 28 | 2 | 0 |  | 53_sas.sas |
| scala | 13 | 67 | 15 | 0 | 0 |  | 25_scala.scala |
| scheme | 345 | 12 | 26 | 2 | 0 |  | 64_scheme.scm |
| scilab | 10 | 20 | 2 | 0 | 0 |  | 78_scilab.sce |
| sh | 11 | 103 | 96 | 41 | 0 | ja | 08_shell.sh |
| sml | 12 | 50 | 28 | 4 | 0 |  | 71_standardml.sml |
| solidity | 82 | 20 | 13 | 0 | 0 |  | 42_solidity.sol |
| sql | 66 | 3 | 9 | 0 | 0 |  | 03_sql.sql, 35_plpgsql.sql, 43_plsql.sql, 55_tsql.sql |
| st | 0 | 10 | 6 | 0 | 0 |  | 72_smalltalk.st |
| stata | 132 | 5 | 214 | 3 | 0 |  | 76_stata.do |
| swift | 19 | 30 | 12 | 0 | 0 |  | 15_swift.swift |
| systemverilog | 73 | 29 | 7 | 0 | 0 |  | 66_systemverilog.sv |
| tcl | 61 | 15 | 34 | 2 | 0 |  | 49_tcl.tcl |
| typescript | 912 | 104 | 56 | 126 | 0 |  | 05_typescript.ts |
| uc | 18 | 27 | 6 | 3 | 0 |  | 74_unrealscript.uc |
| vb | 271 | 17 | 5 | 0 | 0 |  | 21_visualbasic.vb, 61_vbscript.vbs, 90_vb6.bas, 94_vba.bas |
| verilog | 28 | 29 | 6 | 0 | 0 |  | 59_verilog.v |
| vhdl | 27 | 27 | 1 | 0 | 0 |  | 60_vhdl.vhd |
| vim | 217 | 248 | 82 | 19 | 3 | ja | 52_vimscript.vim |
| yaml | 3 | 37 | 7 | 7 | 0 |  |  |
| zig | 17 | 15 | 5 | 0 | 0 |  | 37_zig.zig |
