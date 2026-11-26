# Formen-Rechner - Testdateien fuer den Theme-Vergleich (gvim / VS Code)

29 selbst geschriebene Programme (je ca. 100-230 Zeilen), alle mit derselben Aufgabe.
Eigener Code, frei verwendbar (CC0). Nichts kopiert.

## Was das Programm macht

Ein Formen-Rechner mit kleinem Zahlen-Teil:

- Formen **Kreis**, **Rechteck**, **Dreieck** mit Flaeche, Umfang, Eckenzahl
  (Dreieck per Satz des Heron, Wurzel per Newton-Verfahren)
- ungueltige Masse loesen eine **eigene Ausnahme** aus (Dreieck 1/2/10)
- Formen werden nach Flaeche sortiert (Lambda / Vergleichsfunktion)
- **ggT** (Euklid), **Primzahltest** (Probedivision), **Wurzel** (Newton)
- Konstanten und Zahlenliteralformen: Gleitkomma, Exponent (1e-9), Hex (0xFF),
  Binaer (0b10101010), Unterstriche (1_000_000), wo die Sprache sie kennt

Erwartete Ausgabe: `expected.txt` (Assembly: `expected_assembly.txt`, nur Ganzzahlen).

## Dateien, Ausfuehren, Teststatus

"getestet" heisst: gebaut, ausgefuehrt, Ausgabe identisch zu `expected.txt`.

| Nr | Datei | Aufruf | Status |
|---|---|---|---|
| 01 | 01_python.py | `python3 01_python.py` | getestet |
| 02 | 02_javascript.js | `node 02_javascript.js` | getestet |
| 03 | 03_sql.sql | `sqlite3 :memory: < 03_sql.sql` (SQLite) | getestet |
| 04 | 04_java.java | `java 04_java.java` | getestet |
| 05 | 05_typescript.ts | `tsc --target es2020 --strict --outDir out 05_typescript.ts && node out/05_typescript.js` | getestet |
| 06 | 06_csharp.cs | .NET 8, Einstiegspunkt `FormenRechner.Programm` | getestet |
| 07 | 07_cpp.cpp | `g++ -std=c++17 07_cpp.cpp -o formen` | getestet |
| 08 | 08_shell.sh | `bash 08_shell.sh` (Gleitkomma ueber awk) | getestet |
| 09 | 09_c.c | `gcc -std=c11 09_c.c -o formen -lm` | getestet |
| 10 | 10_php.php | `php 10_php.php` | getestet |
| 11 | 11_r.R | `Rscript 11_r.R` | getestet |
| 12 | 12_go.go | `go run 12_go.go` | getestet |
| 13 | 13_rust.rs | `rustc 13_rust.rs -o formen` | getestet |
| 14 | 14_powershell.ps1 | `pwsh -File 14_powershell.ps1` (PowerShell 7) | **nicht ausgefuehrt**, nur Parser |
| 15 | 15_swift.swift | `swiftc 15_swift.swift -o formen` | **nicht ausgefuehrt**, nur Parser |
| 16 | 16_kotlin.kt | `kotlinc 16_kotlin.kt -include-runtime -d f.jar && java -jar f.jar` | getestet (Kotlin 1.3) |
| 17 | 17_ruby.rb | `ruby 17_ruby.rb` | getestet |
| 18 | 18_assembly.asm | `nasm -f elf64 18_assembly.asm -o f.o && ld f.o -o f && ./f` (x86-64 Linux) | getestet (eigene Ausgabe) |
| 19 | 19_dart.dart | `dart run 19_dart.dart` (Dart 3) | **nicht ausgefuehrt**, nur Parser |
| 20 | 20_objectivec.m | Foundation noetig (macOS: `clang -fobjc-arc -framework Foundation`) | getestet (GNUstep + Clang) |
| 21 | 21_visualbasic.vb | .NET 8, Einstiegspunkt `Programm` | getestet |
| 22 | 22_lua.lua | `lua5.4 22_lua.lua` | getestet |
| 23 | 23_ada.adb | `gnatchop -w 23_ada.adb && gnatmake -gnat2012 formen && ./formen` | getestet |
| 24 | 24_fortran.f90 | `gfortran -std=f2008 24_fortran.f90 -o formen` | getestet |
| 25 | 25_scala.scala | `scalac 25_scala.scala && scala Formen` (laeuft auch mit scala-cli) | getestet (Scala 2.11) |
| 26 | 26_perl.pl | `perl 26_perl.pl` | getestet |
| 27 | 27_matlab.m | als `formen.m` speichern, dann `formen` (MATLAB oder Octave) | getestet (Octave 8) |
| 28 | 28_delphi.pas | `fpc -Mdelphi 28_delphi.pas` (Delphi-Dialekt) | getestet (Free Pascal) |
| 29 | 29_julia.jl | `julia 29_julia.jl` | **nicht ausgefuehrt**, nur Parser |

25 von 29 Dateien liefen real. Swift, Dart, PowerShell und Julia liessen sich in dieser
Umgebung nicht installieren; sie sind von Hand sorgfaeltig geschrieben und mit dem
tree-sitter-Parser auf Syntaxfehler geprueft (Swift, Dart, Julia: keine; PowerShell: der
Parser kennt drei gueltige Konstrukte nicht - `0b`-Literal und Basisklassen-Konstruktoraufruf).

## Bekannte Abweichungen (bewusst)

- **Assembly**: nur Ganzzahlen (kein Kreis); Wurzel ganzzahlig, skaliert (`Wurzel(2000000) = 1414`).
- **SQL**: SQLite-Dialekt; Newton, ggT und Primzahlen als rekursive Abfragen; keine Binaer-
  oder Unterstrich-Literale.
- **Fortran**: keine Ausnahmen, der Fehlerfall wird vorab geprueft.
- **C**: keine Klassen; Enum + Struct, Fehler per Rueckgabewert.
- **Literale**: Binaerliterale fehlen in Lua, R, Dart, Scala, SQL, Delphi (Free Pascal);
  Unterstriche fehlen in den meisten aelteren Sprachen. Das ist Absicht - jede Datei nutzt
  das, was die Sprache hergibt.
- **Java**: Hauptklasse nicht `public` und als erste Klasse, damit `java 04_java.java` laeuft.
- **Ada**: `Form` heisst `Figur`, weil `Ada.Text_IO.Form` sonst kollidiert.
- Ausgabetexte und Kommentare sind reines ASCII (keine Umlaute), damit Kodierung nie stoert.

## Was in jeder Datei fuer Themes sichtbar wird

Lizenz-/Kopfkommentar, Doc-Kommentar (wo die Sprache ihn kennt), Zeilen-, Block- und
Trailing-Kommentar, `TODO`-Marker, Konstanten, Zahlenliteralformen, String-Interpolation oder
Format-Strings, Klassen/Interfaces/Vererbung, Ausnahmen (throw/try/catch), Verzweigungen
(if, ternary, switch/match), Schleifen (for, while), Lambdas/Funktionsobjekte, Operatoren
(arithmetisch, Vergleich, logisch, Bit), Rueckgabetypen und Typannotationen.
