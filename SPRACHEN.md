# Sprachen

Rangliste der Programmiersprachen, aus der die Testprogramme in `test/` stammen.
Die Testprogramme der 23 Sprachen ohne eigene Vim-Syntax sind entfernt (Spalte Testdatei).
Eigene Zusammensetzung, keine TIOBE-Kopie.

## Methode

Pro Quelle wird der Rang in einen Score umgerechnet (logarithmischer Abfall, Rang 1 = 100).
Die Scores werden gewichtet gemittelt. Fehlt eine Sprache in einer Quelle, wird ein angenommener
Rang fuer "nicht gelistet" eingesetzt; Quellen ohne Wert (z. B. SQL bei GitHub/RedMonk) werden
herausgerechnet und die Gewichte neu normiert.

Rangliste 100: `Score = 100 * (1 - ln(Rang)/ln(151))`

| Quelle | Gewicht |
|---|---|
| Stack-Overflow-Umfrage (Nutzung, ueber 40 Sprachen) | 25 % |
| GitHub Innovation Graph, Entwickler mit Push pro Sprache, 2026-Q2 (selbst ausgewertet) | 25 % |
| TIOBE Okt/Nov 2026 (bis Rang 46, dazu Band 51-100) | 15 % |
| US-Stellenanzeigen (nur 10 Sprachen) | 15 % |
| RedMonk Jan 2026 (Top 20) | 10 % |
| PYPL 2026 | 10 % |

Aufgenommen sind nur echte Programmiersprachen. Konfigurations-, Build-, Template-, Markup-,
Schnittstellen- und Parser-Generator-Sprachen sowie esoterische Sprachen sind ausgeschlossen.
Scratch fehlt (nicht messbar).

## Einschraenkungen

- Bis etwa Rang 40 stuetzen mehrere Quellen die Reihenfolge; ab etwa Rang 65 stammt sie praktisch
  nur noch aus GitHub-Entwicklerzahlen und ist grob.
- GitHub verzerrt: Sprachen mit viel oeffentlichem Code (Batch, PL/pgSQL, Hack) liegen hoeher,
  solche mit wenig (Ada, Visual Basic, COBOL) niedriger. SQL hat keinen GitHub-Wert.
- Die Rangzahlen der ersten 29 haben sich gegenueber der 29er-Liste verschoben (z. B. Ada 30 statt 23);
  neu in den Top 29 sind Nix (27) und Batch (29).
- Stack-Overflow-Prozentwerte jenseits der Top 23 stammen aus einer Sekundaerquelle.
- Die TIOBE-Raenge 21-50 stammen aus einer Sekundaerquelle (Okt 2026), nicht von tiobe.com direkt.
- Die Python-Skripte zur Berechnung lagen nicht im Ordner. Die Werte sind hier festgehalten,
  lassen sich aus diesem Repository aber nicht neu berechnen.

## Rangliste 100

GitHub, SO (Stack Overflow) und TIOBE: Rang in der Quelle, leer = kein Wert.
Einzelraenge der anderen Quellen sind nicht erfasst.

Spalte Vim: bringt Vim 9.2.0858 ohne Plugins eine Syntax mit (geprueft an der Testdatei,
26.11.2026)? "ja" heisst nur, dass eine passende Syntax geladen wird, nicht wie gut sie faerbt.
Ergebnis: 76 ja, 1 vorhanden aber falsch erkannt, 23 ohne eigene Syntax.

| Rang | Sprache | Score | GitHub | SO | TIOBE | Vim | Testdatei |
|---:|---|---:|---:|---:|---:|---|---|
| 1 | Python | 89.7 | 2 | 3 | 1 | ja | `01_python.py` |
| 2 | JavaScript | 86.9 | 1 | 1 | 6 | ja | `02_javascript.js` |
| 3 | Java | 72.9 | 5 | 6 | 3 | ja | `04_java.java` |
| 4 | SQL | 70.3 |  | 2 | 8 | ja | `03_sql.sql` |
| 5 | C++ | 64.6 | 6 | 9 | 4 | ja | `07_cpp.cpp` |
| 6 | TypeScript | 60.9 | 3 | 5 | 38 | ja | `05_typescript.ts` |
| 7 | C# | 60.2 | 11 | 7 | 5 | ja | `06_csharp.cs` |
| 8 | C | 59.2 | 7 | 10 | 2 | ja | `09_c.c` |
| 9 | Shell (Bash) | 57.0 | 4 | 4 | 50 | ja | `08_shell.sh` |
| 10 | PHP | 50.8 | 10 | 12 | 12 | ja | `10_php.php` |
| 11 | R | 49.1 | 24 | 20 | 7 | ja | `11_r.R` |
| 12 | Go | 47.3 | 16 | 13 | 10 | ja | `12_go.go` |
| 13 | Rust | 45.5 | 17 | 11 | 11 | ja | `13_rust.rs` |
| 14 | Swift | 43.9 | 14 | 17 | 18 | ja | `15_swift.swift` |
| 15 | PowerShell | 43.4 | 9 | 8 | 42 | ja | `14_powershell.ps1` |
| 16 | Kotlin | 40.4 | 12 | 14 | 32 | ja | `16_kotlin.kt` |
| 17 | Ruby | 39.4 | 15 | 18 | 28 | ja | `17_ruby.rb` |
| 18 | Objective-C | 39.1 | 18 | 30 | 25 | ja | `20_objectivec.m` |
| 19 | Dart | 37.2 | 20 | 19 | 20 | ja | `19_dart.dart` |
| 20 | Assembly | 35.5 | 22 | 16 | 17 | ja | `18_assembly.asm` |
| 21 | Lua | 34.7 | 19 | 15 | 32 | ja | `22_lua.lua` |
| 22 | Perl | 33.5 | 23 | 25 | 15 | ja | `26_perl.pl` |
| 23 | MATLAB | 32.1 | 28 | 26 | 16 | ja | `27_matlab.m` |
| 24 | Fortran | 30.6 | 33 | 34 | 13 | ja | `24_fortran.f90` |
| 25 | Visual Basic | 30.0 | 68 | 23 | 9 | ja | `21_visualbasic.vb` |
| 26 | Scala | 29.5 | 42 | 32 | 38 | ja | `25_scala.scala` |
| 27 | Nix | 28.6 | 21 | 21 |  | ja | `27_nix.nix` |
| 28 | Delphi | 28.3 | 43 | 33 | 19 | ja | `28_delphi.pas` |
| 29 | Batch | 28.1 | 8 |  |  | ja | `29_batch.bat` |
| 30 | Ada | 28.0 | 78 | 38 | 21 | ja | `23_ada.adb` |
| 31 | Julia | 27.6 | 41 | 35 | 23 | ja | `29_julia.jl` |
| 32 | Groovy | 26.2 | 39 | 24 | 75 | ja | `32_groovy.groovy` |
| 33 | Haskell | 26.2 | 45 | 31 | 39 | ja | `33_haskell.hs` |
| 34 | Lisp | 25.9 | 55 | 28 | 36 | ja | `34_lisp.lisp` |
| 35 | PL/pgSQL | 25.7 | 13 |  |  | ja, verwandt: Oracle-SQL | `35_plpgsql.sql` |
| 36 | GDScript | 25.5 | 37 | 22 |  | ja | `36_gdscript.gd` |
| 37 | Zig | 25.1 | 58 | 27 | 46 | ja | `37_zig.zig` |
| 38 | OCaml | 24.9 | 59 | 39 | 26 | ja | `38_ocaml.ml` |
| 39 | COBOL | 24.7 | 79 | 41 | 16 | ja | `39_cobol.cob` |
| 40 | Elixir | 24.2 | 48 | 29 | 75 | **nein** | entfernt |
| 41 | Prolog | 24.2 | 57 | 42 | 31 | vorhanden, aber als Perl erkannt | `41_prolog.pl` |
| 42 | Solidity | 24.0 | 34 | 43 | 75 | ja | `42_solidity.sol` |
| 43 | PL/SQL | 23.5 | 47 |  | 30 | ja | `43_plsql.sql` |
| 44 | Clojure | 22.7 | 51 | 37 | 75 | ja | `44_clojure.clj` |
| 45 | Hack | 22.5 | 25 |  |  | **nein** | entfernt |
| 46 | HLSL | 22.3 | 26 |  |  | **nein** | entfernt |
| 47 | GLSL | 22.1 | 27 |  |  | ja | `47_glsl.glsl` |
| 48 | Erlang | 22.1 | 60 | 36 | 75 | ja | `48_erlang.erl` |
| 49 | Tcl | 21.8 | 38 |  | 75 | ja | `49_tcl.tcl` |
| 50 | CUDA | 21.7 | 29 |  |  | ja | `50_cuda.cu` |
| 51 | D | 21.6 | 63 |  | 34 | ja | `51_d.d` |
| 52 | Vim Script | 21.6 | 30 |  |  | ja | `52_vimscript.vim` |
| 53 | SAS | 21.5 | 84 |  | 22 | ja | `53_sas.sas` |
| 54 | Cython | 21.4 | 31 |  |  | ja, verwandt: Pyrex | `54_cython.pyx` |
| 55 | T-SQL | 21.2 | 32 |  |  | ja, verwandt: Oracle-SQL | `55_tsql.sql` |
| 56 | F# | 21.1 | 66 | 40 | 75 | **nein** | entfernt |
| 57 | Emacs Lisp | 20.8 | 35 |  |  | ja, verwandt: Lisp | `57_emacslisp.el` |
| 58 | AWK | 20.7 | 36 |  |  | ja | `58_awk.awk` |
| 59 | Verilog | 20.1 | 40 |  |  | ja | `59_verilog.v` |
| 60 | VHDL | 20.0 | 54 |  | 75 | ja | `60_vhdl.vhd` |
| 61 | VBScript | 19.7 | 44 |  |  | ja, verwandt: Visual Basic | `61_vbscript.vbs` |
| 62 | ABAP | 19.6 | 97 |  | 33 | ja | `62_abap.abap` |
| 63 | Pawn | 19.4 | 46 |  |  | **nein** | entfernt |
| 64 | Scheme | 19.1 | 49 |  |  | ja | `64_scheme.scm` |
| 65 | Raku | 19.0 | 50 |  |  | ja | `65_raku.raku` |
| 66 | SystemVerilog | 18.8 | 52 |  |  | ja | `66_systemverilog.sv` |
| 67 | Nim | 18.7 | 70 |  | 75 | **nein** | entfernt |
| 68 | AppleScript | 18.7 | 53 |  |  | **nein** | entfernt |
| 69 | Apex | 18.6 | 72 |  | 75 | **nein**, laedt Rexx | entfernt |
| 70 | PureBasic | 18.5 | 56 |  |  | **nein** | entfernt |
| 71 | Standard ML | 18.0 | 61 |  |  | ja | `71_standardml.sml` |
| 72 | Smalltalk | 17.9 | 62 |  |  | ja | `72_smalltalk.st` |
| 73 | CoffeeScript | 17.8 | 64 |  |  | **nein**, laedt conf | entfernt |
| 74 | UnrealScript | 17.7 | 65 |  |  | ja | `74_unrealscript.uc` |
| 75 | Lean | 17.6 | 67 |  |  | **nein** | entfernt |
| 76 | Stata | 17.4 | 69 |  |  | ja | `76_stata.do` |
| 77 | Forth | 17.3 | 71 |  |  | ja | `77_forth.fth` |
| 78 | Scilab | 17.1 | 73 |  |  | ja | `78_scilab.sce` |
| 79 | AutoHotkey | 17.1 | 74 |  |  | ja | `79_autohotkey.ahk` |
| 80 | Processing | 17.0 | 75 |  |  | ja, verwandt: Arduino/C++ | `80_processing.pde` |
| 81 | Limbo | 16.9 | 76 |  |  | **nein**, laedt conf | entfernt |
| 82 | Nu | 16.9 | 77 |  |  | ja | `82_nu.nu` |
| 83 | Racket | 16.7 | 80 |  |  | ja | `83_racket.rkt` |
| 84 | Reason | 16.6 | 81 |  |  | **nein** | entfernt |
| 85 | PureScript | 16.6 | 82 |  |  | **nein** | entfernt |
| 86 | Mojo | 16.5 |  | 44 | 75 | ja | `86_mojo.mojo` |
| 87 | SourcePawn | 16.5 | 83 |  |  | **nein**, laedt SPICE | entfernt |
| 88 | Agda | 16.4 | 85 |  |  | **nein** | entfernt |
| 89 | Mercury | 16.3 | 86 |  |  | **nein**, laedt MATLAB | entfernt |
| 90 | Visual Basic 6.0 | 16.3 | 87 |  |  | ja | `90_vb6.bas` |
| 91 | ReScript | 16.2 | 88 |  |  | **nein** | entfernt |
| 92 | Motoko | 16.1 | 89 |  |  | **nein**, laedt GDMO | entfernt |
| 93 | Haxe | 16.1 | 90 |  |  | **nein** | entfernt |
| 94 | VBA | 16.0 | 92 |  |  | ja | `94_vba.bas` |
| 95 | OpenEdge ABL | 15.9 | 93 |  |  | ja | `95_openedge.p` |
| 96 | ActionScript | 15.9 | 94 |  |  | **nein**, laedt Atlas | entfernt |
| 97 | Move | 15.8 | 96 |  |  | **nein** | entfernt |
| 98 | Elm | 15.7 | 98 |  |  | ja | `98_elm.elm` |
| 99 | Terra | 15.6 | 99 |  |  | **nein**, laedt TADS | entfernt |
| 100 | BASIC | 15.6 | 100 |  |  | ja | `100_basic.bas` |

## Weitere Kandidaten (ab Rang 101, ohne Testdatei)

| Rang | Sprache | Score |
|---:|---|---:|
| 101 | Rebol | 15.5 |
| 102 | Odin | 15.5 |
| 103 | Euphoria | 15.4 |
| 104 | Cadence | 15.4 |
| 105 | Vala | 15.3 |
| 106 | Crystal | 15.3 |
| 107 | Mathematica | 15.2 |
| 108 | Io | 15.2 |
| 109 | XQuery | 15.1 |
| 110 | Clean | 15.1 |
| 111 | eC | 15.0 |
| 112 | Factor | 15.0 |
| 113 | Xtend | 15.0 |
| 114 | ColdFusion | 14.9 |
| 115 | Q# | 14.9 |
| 116 | V | 14.8 |
| 117 | Gleam | 14.8 |
| 118 | Ballerina | 14.7 |
| 119 | Red | 14.7 |
| 120 | Modula-3 | 14.7 |
| 121 | Vyper | 14.6 |
| 122 | Cairo | 14.6 |
| 123 | Eiffel | 14.5 |
| 124 | Squirrel | 14.5 |
| 125 | REXX | 14.5 |
| 126 | LiveScript | 14.4 |
| 127 | LabVIEW | 14.4 |
| 128 | J | 14.3 |
| 129 | AutoIt | 14.3 |
| 130 | Janet | 14.3 |
| 131 | Fennel | 14.2 |
| 132 | Hy | 14.2 |
| 133 | Pike | 14.1 |
| 134 | Modula-2 | 14.1 |
| 135 | Dafny | 14.1 |
| 136 | HolyC | 14.0 |
| 137 | Component Pascal | 14.0 |
| 138 | DataWeave | 14.0 |
| 139 | Idris | 13.9 |

## Fruehere Rangliste 29

`Score = 100 * (1 - ln(Rang)/ln(41))`. Quellen und Gewichte: Stack-Overflow-Umfrage 25 %,
US-Stellenanzeigen 25 %, GitHub Octoverse 20 %, RedMonk 10 %, TIOBE 10 %, PYPL 10 %.
Die drei letzten Spalten zeigen den Rang in Varianten (zur Robustheitspruefung).

| Rang | Sprache | Score | gleiche Gewichte | ohne Suchquellen | ohne Umfrage/Jobs |
|---:|---|---:|---:|---:|---:|
| 1 | Python | 87.0 | 1 | 1 | 1 |
| 2 | JavaScript | 75.1 | 2 | 3 | 3 |
| 3 | SQL | 66.8 | 4 | 2 | 12 |
| 4 | Java | 65.3 | 3 | 5 | 2 |
| 5 | TypeScript | 53.9 | 7 | 4 | 4 |
| 6 | C# | 50.6 | 6 | 7 | 6 |
| 7 | C++ | 50.0 | 5 | 8 | 5 |
| 8 | Shell | 45.0 | 11 | 6 | 13 |
| 9 | C | 39.0 | 8 | 11 | 7 |
| 10 | PHP | 36.6 | 9 | 9 | 8 |
| 11 | R | 34.8 | 10 | 13 | 9 |
| 12 | Go | 33.8 | 12 | 10 | 10 |
| 13 | Rust | 28.8 | 13 | 14 | 14 |
| 14 | PowerShell | 26.3 | 16 | 12 | 26 |
| 15 | Swift | 26.0 | 14 | 17 | 11 |
| 16 | Kotlin | 23.1 | 18 | 15 | 22 |
| 17 | Ruby | 22.7 | 17 | 16 | 16 |
| 18 | Assembly | 21.7 | 21 | 20 | 25 |
| 19 | Dart | 21.4 | 20 | 19 | 19 |
| 20 | Objective-C | 21.2 | 15 | 23 | 15 |
| 21 | Visual Basic | 20.9 | 19 | 22 | 17 |
| 22 | Lua | 20.6 | 26 | 18 | 29 |
| 23 | Ada | 19.0 | 22 | 29 | 18 |
| 24 | Fortran | 18.1 | 23 | 27 | 20 |
| 25 | Scala | 18.0 | 24 | 21 | 21 |
| 26 | Perl | 17.8 | 25 | 24 | 23 |
| 27 | MATLAB | 17.6 | 27 | 25 | 24 |
| 28 | Delphi | 17.1 | 28 | 28 | 27 |
| 29 | Julia | 16.6 | 29 | 26 | 28 |
