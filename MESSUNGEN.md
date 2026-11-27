# Messungen

Wie genau trifft die Erweiterung die Darstellung von Vim?

## Faerben ohne Vim (Stand 27.11.2026)

Die Erweiterung faerbt selbst (`faerben.js`), Vim dient nur als Vergleich. Vim 9.2, Patches
1-858, unter Linux; ohne vimrc und Plugins. **Rechnerisch:** Was VS Code tatsaechlich anzeigt,
ist nicht geprueft.

| Probe | Ergebnis |
|---|---|
| Fertiges Paket (nachgebildetes VS Code): 80 Testdateien in 34 Themes, Gruppe je Zeichen | 2720 Kombinationen, keine Abweichung |
| `measure.js`: Farbe, Stil und Hintergrund je Zeichen, 34 Themes | keine Abweichung |
| Stichprobe von 438 C- und C++-Dateien und Headern, default light | keine Abweichung |
| Dateityp-Erkennung gegen Vim, 2529 Dateien | gleich |
| Jede Testdatei mit den Regeln jeder Sprache (Suche nach Haengern) | keine |

COBOL: `39_cobol.cob` war anfangs im freien Format, das Vims Regeln nicht kennen (rund 56 % der
Zeichen als Error, in Vim wie in der Erweiterung). Die Datei ist jetzt im festen Format. In der
alten Fassung gab es eine Abweichung von 8 Zeichen: Vim zeigte bei einer Zeichenkette ueber
Spalte 73 Error, die Erweiterung nicht. Das ist nicht behoben.

Behoben in 0.2.1: Vim zaehlt die Spalte 73 (und 7) in Bytes, die Erweiterung zaehlte Zeichen.
Mit Umlauten davor begann Error an einer anderen Stelle als in Vim.

Die Testdateien dienten auch zum Beheben der Fehler. Sie sagen deshalb wenig darueber, wie
genau anderer Code getroffen wird.

### BibTeX

| Probe | Ergebnis |
|---|---|
| Testdatei und 10 `.bib`-Dateien des Systems in 34 Themes | keine Abweichung |
| 40 `.bib`-Dateien des Systems, default light | keine Abweichung |
| 600 Dateien mit zufaellig zusammengewuerfeltem Text | in 4 Dateien je ein Zeichen anders |

Die vier Zeichen sind ein Komma in fehlerhafter Eingabe (eine schliessende Klammer direkt
davor, im Schluessel eines Eintrags). Das bleibt so.

### Shell: Listen ueber mehrere Zeilen und "function name()"

| Probe | Ergebnis |
|---|---|
| nvm.sh und install.sh von nvm | vorher 2235 und 208 Zeichen anders, jetzt keines |
| 990 Shell-Dateien des Systems | 8 anders gefaerbt als vorher, alle 8 jetzt wie in Vim |
| 7102 Dateien in 92 Dateitypen, alt gegen neu | nur ein Syntax-Test von Vim anders, jetzt wie in Vim |
| Alle 95 Testdateien, default light | keine Abweichung |

Behoben in "faerben.js":

- Eine "oneline"-Region geht weiter, wenn etwas darin bis ans Zeilenende reicht (zum Beispiel
  "\\" am Ende).
- "\\ze" innerhalb von Klammern eines Suchmusters wirkt jetzt wie in Vim. Betraf
  "function name()" in bash.
- Bis ans Zeilenende reicht wie in Vim nur ein Muster mit "$" oder "\\_$".

Noch anders sind 10 Syntax-Tests von Vim, vor allem zu den Varianten der Korn-Shell (Vim hat
fuer ksh93, ksh88 und mksh eigene Regeln, hier gibt es nur einen Regelsatz) und zu
"${ befehl; }" von bash 5.3 ueber mehrere Zeilen.

### TeX (LaTeX, Plain TeX, Stildateien, dtx)

| Probe | Ergebnis |
|---|---|
| Alle 95 Testdateien in 34 Themes (fertiges Paket, nachgebildetes VS Code) | 3230 Kombinationen, keine Abweichung |
| 11 TeX-Dateien des Systems in 34 Themes | 374 Kombinationen, keine Abweichung |
| 1526 TeX-Dateien des Systems, default light | keine Abweichung |
| Dateityp-Erkennung gegen Vim, 4000 Dateien | gleich |
| 5000 Zeilen LaTeX faerben (Linux) | rund 1 Sekunde |

Mit diesen Dateien wurden die Fehler gefunden und behoben; die Zahlen sind der Stand danach.

Behoben, betrifft alle Sprachen:

- Passt an einer Stelle eine Regel, die dort schon offen ist (Klammern, die sich selbst
  enthalten), sucht Vim erst ab dem naechsten Zeichen weiter.
- Ueberspringt "nextgroup" mit "skipwhite" Leerraum, koennen andere Regeln danach nicht in
  diesen Leerraum zurueckreichen.
- "cchar=" mit einem Leerzeichen wurde nicht verstanden.

Die messbaren Ergebnisse der anderen Sprachen sind unveraendert (Vergleich alt/neu an 1410
Dateien in 39 Sprachen).

### XML, SCSS, Less, INI, Makefile, Dockerfile, Diff, JSX, TSX, jsonc, TOML

| Probe | Ergebnis |
|---|---|
| Alle 91 Testdateien in 34 Themes (fertiges Paket, nachgebildetes VS Code) | 3094 Kombinationen, keine Abweichung |
| 545 Dateien des Systems, default light | 542 gleich, 3 mit je einem Zeichen ohne sichtbare Farbe |
| Dateityp-Erkennung gegen Vim, 3597 Dateien | gleich |

Less und JSX sind nur an ihrer Testdatei geprueft, TSX an zwei Dateien.

Behoben: Heisst die Gruppe am Ende einer Region wie die Region selbst (`matchgroup`), faerbt
Vim das Ende nicht gesondert (aufgefallen bei Makefile-Zielzeilen).

### Neue Dateien je Sprache

Bis zu 12 Dateien je Sprache aus Vims Syntax-Tests (`runtime/syntax/testdir/input`) und aus dem
Linux-System, die beim Bauen nicht verwendet waren; default light, Gruppe je Zeichen.

| Stand | Dateien gleich |
|---|---|
| Erster Lauf | 309 von 322 (39 Sprachen) |
| Nach den Korrekturen | 320 von 322 |

Die zwei uebrigen sind HTML-Vorlagen (Jinja), die nur als HTML gefaerbt werden. Auch diese
Dateien dienten dann zum Beheben; 320 von 322 ist deshalb kein Mass fuer weiteren Code.

Korrigiert: Shell (Vim waehlt bash, ksh oder POSIX nach der ersten Zeile), Perl (`sub {`),
Tcl (`he=` in Regionen mit `keepend`). Die Shell-Dateien stimmen in allen 34 Themes (13
Dateien), die Wahl der Shell wie bei Vim (210 Dateien).

Ohne neue Datei blieben 34 Sprachen: abap, ada, arduino, autohotkey, basic, clojure, cobol,
dart, elm, erlang, forth, gdscript, haskell, julia, kotlin, mojo, nix, nu, ocaml, prolog,
racket, raku, rust, sas, scala, scheme, scilab, solidity, stata, swift, uc, verilog, vhdl, zig.

## Fruehere Version: Vim faerbt (Stand 26.11.2026)

- 75 Testprogramme aus `test/`, je ein Programm pro Sprache (siehe [SPRACHEN.md](SPRACHEN.md))
- 34 Themes: alle 28 Farbschemata von Vim 9.2, sechs davon hell und dunkel
- blue dark, default light und elflord dark stammen vom Vim des Autors, die uebrigen 31 vom Vim unten
- Vim 9.2, Patches 1-858, unter Linux aus den Quellen gebaut (nicht unter Windows)
- Soll: `vim/reference.vim`. Ist: Tokens der Erweiterung und Theme-Datei.
- **Rechnerisch.** Was VS Code tatsaechlich anzeigt, ist darin nicht geprueft.

## Ergebnis je Theme

**Alle 34 Themes: keine Abweichungen** in den 75 Dateien.

Anteil richtiger Zeichen in % (ohne Leerraum). Hg.Leer: hinterlegter Leerraum (- = keiner vorhanden).
Hinterlegt und gemessen werden die voreingestellten Gruppen Todo, Error und Constant.

| Theme | Zeichen | Farbe | Stil | Hintergrund | alles | Hg.Leer |
|---|---:|---:|---:|---:|---:|---:|
| blue dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| catppuccin dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | - |
| catppuccin light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | - |
| darkblue dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| default light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| delek light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| desert dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| elflord dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| evening dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| habamax dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| industry dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| koehler dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| lunaperche dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| lunaperche light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| morning light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| murphy dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| novum dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| novum light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| pablo dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| peachpuff light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| quiet dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| quiet light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| retrobox dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| retrobox light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| ron dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| shine light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| slate dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| sorbet dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| torte dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| unokai dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| wildcharm dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| wildcharm light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| zaibatsu dark | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| zellner light | 238321 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |

Gegenprobe: Mit absichtlich falscher Kommentarfarbe sinkt default auf 82,9 %, die Messung schlaegt also an.

## Offene Probleme, nach Wichtigkeit

Stand der frueheren Version; Nr. 2 entfaellt ohne Vim. Die Reihenfolge ist ein Vorschlag.

| Nr | Problem | Stand |
|---:|---|---|
| 1 | Erst ein Teil der Sprachen und Themes wurde in VS Code angesehen. Andere Spracherweiterungen mit eigenen Semantic Tokens koennen Vorrang bekommen. | nur gerechnet |
| 2 | Grosse Dateien: Dateien mit 10000 bis 17000 Zeilen brauchen unter Linux 3 bis 7 s (eine davon unter Windows rund 4,5 s). Vim startet bei jeder Aenderung neu; ueber `maxLines` (3000) wird nicht gefaerbt. | gemessen, nicht geloest |
| 3 | Cursorzeile, Zeilennummern, Auswahl und Suchtreffer haben die Farben von VS Code, nicht die von Vim. | nicht gebaut |
| 4 | `.vimrc`, `_vimrc` und `.gvimrc` werden vermutlich nicht erfasst. | nicht gebaut |

## Behobene Abweichungen

| Abweichung | Ursache und Loesung |
|---|---|
| Clojure 92,7 %, Scheme 96,0 %, Zig 99,6 %, ein `:` in Perl | Dateityp-Plugins fehlten; `tokens.vim` laedt sie jetzt wie gVim (ohne externe Programme) |
| morning light 87,6 % (Hintergrund von Zahlen und Zeichenketten) | `Constant` zu den hinterlegten Gruppen genommen |
| Prolog wurde als Perl erkannt | Vim entscheidet nach der ersten Zeile; Testdatei angepasst |
| Mit der `vim.exe` aus gVim brach `tokens.vim` ab (E954) | `termguicolors` wird mit `silent!` gesetzt |
| Bei blue war der Error-Kasten einmal rot statt koralle | spaeter korrekt koralle; Ursache nicht gefunden |

## Syntaxdaten

Gegenprobe der Daten, aus denen die Erweiterung faerbt: Faerbt Vim nur aus diesen
Daten wie mit seinen eigenen Syntaxdateien?

| Probe | Ergebnis |
|---|---|
| Linux, Vim 9.2.0858: 75 Testdateien | alle gleich (0 von 199048 Zeichen anders) |
| Linux: json, html, css, markdown, yaml mit kurzen Beispielen, die nicht im Repository sind | alle gleich (0 von 2439 Zeichen anders) |
| Neu erzeugt in einem anderen Ordner | gleicher Inhalt |
| Windows, gVim (gebaut am 14.02.2026) | `08_shell.sh` weicht ab (265 Zeichen), die uebrigen Testdateien sind gleich |

Bei gVim ist vermutlich der aeltere Stand von `syntax/sh.vim` die Ursache; geprueft ist das nicht.
Die Regeln fuer Shell haengen ausserdem vom Inhalt der Datei ab.

## Grenzen der Aussage

- Ein Programm je Sprache: 100 % heisst nicht, dass jedes Sprachkonstrukt geprueft ist.
- Erkennt Vim eine Datei falsch, stimmen Soll und Ist trotzdem ueberein.
- `default` gibt es nur hell: `:colorscheme default` setzt den Hintergrund zurueck, eine dunkle Fassung
  wird so nicht erzeugt.

## Je Sprache und Theme

Anteil "alles" (Farbe, Stil und Hintergrund richtig) in %. Wegen der 34 Themes in vier Tabellen
geteilt, die Themes alphabetisch, die Sprachen nach Rang.
Die Testdatei je Sprache steht in [SPRACHEN.md](SPRACHEN.md).

### Themes 1 von 4: blue dark bis evening dark

| Rang | Sprache | blue dark | catppuccin dark | catppuccin light | darkblue dark | default light | delek light | desert dark | elflord dark | evening dark |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | Python | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 2 | JavaScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 3 | Java | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 4 | SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 5 | C++ | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 6 | TypeScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 7 | C# | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 8 | C | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 9 | Shell (Bash) | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 10 | PHP | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 11 | R | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 12 | Go | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 13 | Rust | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 14 | Swift | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 15 | PowerShell | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 16 | Kotlin | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 17 | Ruby | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 18 | Objective-C | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 19 | Dart | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 20 | Assembly | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 21 | Lua | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 22 | Perl | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 23 | MATLAB | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 25 | Visual Basic | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 26 | Scala | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 27 | Nix | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 28 | Delphi | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 29 | Batch | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 30 | Ada | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 31 | Julia | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 32 | Groovy | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 33 | Haskell | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 34 | Lisp | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 35 | PL/pgSQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 36 | GDScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 37 | Zig | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 38 | OCaml | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 39 | COBOL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 41 | Prolog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 42 | Solidity | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 43 | PL/SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 44 | Clojure | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 47 | GLSL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 48 | Erlang | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 49 | Tcl | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 50 | CUDA | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 51 | D | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 53 | SAS | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 54 | Cython | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 55 | T-SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 57 | Emacs Lisp | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 58 | AWK | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 59 | Verilog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 60 | VHDL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 61 | VBScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 62 | ABAP | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 64 | Scheme | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 65 | Raku | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 66 | SystemVerilog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 71 | Standard ML | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 72 | Smalltalk | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 74 | UnrealScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 76 | Stata | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 77 | Forth | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 78 | Scilab | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 79 | AutoHotkey | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 80 | Processing | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 82 | Nu | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 83 | Racket | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 86 | Mojo | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 90 | Visual Basic 6.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 94 | VBA | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 95 | OpenEdge ABL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 98 | Elm | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 100 | BASIC | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |

### Themes 2 von 4: habamax dark bis novum light

| Rang | Sprache | habamax dark | industry dark | koehler dark | lunaperche dark | lunaperche light | morning light | murphy dark | novum dark | novum light |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | Python | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 2 | JavaScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 3 | Java | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 4 | SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 5 | C++ | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 6 | TypeScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 7 | C# | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 8 | C | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 9 | Shell (Bash) | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 10 | PHP | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 11 | R | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 12 | Go | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 13 | Rust | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 14 | Swift | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 15 | PowerShell | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 16 | Kotlin | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 17 | Ruby | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 18 | Objective-C | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 19 | Dart | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 20 | Assembly | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 21 | Lua | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 22 | Perl | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 23 | MATLAB | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 25 | Visual Basic | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 26 | Scala | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 27 | Nix | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 28 | Delphi | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 29 | Batch | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 30 | Ada | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 31 | Julia | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 32 | Groovy | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 33 | Haskell | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 34 | Lisp | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 35 | PL/pgSQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 36 | GDScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 37 | Zig | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 38 | OCaml | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 39 | COBOL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 41 | Prolog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 42 | Solidity | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 43 | PL/SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 44 | Clojure | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 47 | GLSL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 48 | Erlang | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 49 | Tcl | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 50 | CUDA | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 51 | D | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 53 | SAS | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 54 | Cython | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 55 | T-SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 57 | Emacs Lisp | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 58 | AWK | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 59 | Verilog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 60 | VHDL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 61 | VBScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 62 | ABAP | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 64 | Scheme | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 65 | Raku | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 66 | SystemVerilog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 71 | Standard ML | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 72 | Smalltalk | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 74 | UnrealScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 76 | Stata | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 77 | Forth | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 78 | Scilab | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 79 | AutoHotkey | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 80 | Processing | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 82 | Nu | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 83 | Racket | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 86 | Mojo | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 90 | Visual Basic 6.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 94 | VBA | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 95 | OpenEdge ABL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 98 | Elm | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 100 | BASIC | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |

### Themes 3 von 4: pablo dark bis shine light

| Rang | Sprache | pablo dark | peachpuff light | quiet dark | quiet light | retrobox dark | retrobox light | ron dark | shine light |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | Python | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 2 | JavaScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 3 | Java | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 4 | SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 5 | C++ | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 6 | TypeScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 7 | C# | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 8 | C | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 9 | Shell (Bash) | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 10 | PHP | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 11 | R | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 12 | Go | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 13 | Rust | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 14 | Swift | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 15 | PowerShell | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 16 | Kotlin | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 17 | Ruby | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 18 | Objective-C | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 19 | Dart | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 20 | Assembly | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 21 | Lua | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 22 | Perl | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 23 | MATLAB | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 25 | Visual Basic | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 26 | Scala | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 27 | Nix | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 28 | Delphi | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 29 | Batch | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 30 | Ada | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 31 | Julia | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 32 | Groovy | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 33 | Haskell | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 34 | Lisp | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 35 | PL/pgSQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 36 | GDScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 37 | Zig | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 38 | OCaml | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 39 | COBOL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 41 | Prolog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 42 | Solidity | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 43 | PL/SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 44 | Clojure | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 47 | GLSL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 48 | Erlang | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 49 | Tcl | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 50 | CUDA | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 51 | D | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 53 | SAS | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 54 | Cython | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 55 | T-SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 57 | Emacs Lisp | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 58 | AWK | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 59 | Verilog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 60 | VHDL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 61 | VBScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 62 | ABAP | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 64 | Scheme | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 65 | Raku | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 66 | SystemVerilog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 71 | Standard ML | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 72 | Smalltalk | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 74 | UnrealScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 76 | Stata | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 77 | Forth | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 78 | Scilab | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 79 | AutoHotkey | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 80 | Processing | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 82 | Nu | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 83 | Racket | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 86 | Mojo | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 90 | Visual Basic 6.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 94 | VBA | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 95 | OpenEdge ABL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 98 | Elm | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 100 | BASIC | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |

### Themes 4 von 4: slate dark bis zellner light

| Rang | Sprache | slate dark | sorbet dark | torte dark | unokai dark | wildcharm dark | wildcharm light | zaibatsu dark | zellner light |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | Python | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 2 | JavaScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 3 | Java | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 4 | SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 5 | C++ | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 6 | TypeScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 7 | C# | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 8 | C | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 9 | Shell (Bash) | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 10 | PHP | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 11 | R | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 12 | Go | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 13 | Rust | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 14 | Swift | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 15 | PowerShell | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 16 | Kotlin | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 17 | Ruby | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 18 | Objective-C | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 19 | Dart | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 20 | Assembly | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 21 | Lua | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 22 | Perl | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 23 | MATLAB | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 25 | Visual Basic | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 26 | Scala | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 27 | Nix | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 28 | Delphi | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 29 | Batch | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 30 | Ada | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 31 | Julia | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 32 | Groovy | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 33 | Haskell | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 34 | Lisp | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 35 | PL/pgSQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 36 | GDScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 37 | Zig | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 38 | OCaml | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 39 | COBOL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 41 | Prolog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 42 | Solidity | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 43 | PL/SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 44 | Clojure | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 47 | GLSL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 48 | Erlang | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 49 | Tcl | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 50 | CUDA | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 51 | D | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 53 | SAS | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 54 | Cython | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 55 | T-SQL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 57 | Emacs Lisp | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 58 | AWK | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 59 | Verilog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 60 | VHDL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 61 | VBScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 62 | ABAP | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 64 | Scheme | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 65 | Raku | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 66 | SystemVerilog | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 71 | Standard ML | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 72 | Smalltalk | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 74 | UnrealScript | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 76 | Stata | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 77 | Forth | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 78 | Scilab | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 79 | AutoHotkey | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 80 | Processing | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 82 | Nu | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 83 | Racket | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 86 | Mojo | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 90 | Visual Basic 6.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 94 | VBA | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 95 | OpenEdge ABL | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 98 | Elm | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |
| 100 | BASIC | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 |

## Wiederholen

    node measure.js <schema> [light|dark]      z. B.  node measure.js morning

Die Einzelheiten stehen danach in `messung/`. Diese Datei wird dabei nicht neu geschrieben.
Alle Themes neu erzeugen: `bash werkzeuge/themes.sh`.
