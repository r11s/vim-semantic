# vim-semantic (VimSem)

Die Farbschemata von Vim im Editor von VS Code und VSCodium, so wie in Vim. **Vim muss dafuer
nicht installiert sein:** Die Erweiterung wendet Vims Syntaxregeln selbst an und zeigt das
Ergebnis als Semantic Tokens. Enthalten sind 34 Themes "VimSem ..." zu den Farbschemata von
Vim 9.2.

Es geht nur um die Darstellung im Editor, nicht um das Verhalten von Vim.

**Das Faerben ohne Vim ist neu und noch ein Versuch.**

## Sprachen

Gefaerbt werden diese Vim-Dateitypen:

abap, ada, arduino, asm, autohotkey, awk, basic, c, clojure, cobol, cpp, cs, css, cuda, d,
dart, dosbatch, elm, erlang, forth, gdscript, glsl, go, groovy, haskell, html, java,
javascript, json, julia, kotlin, lisp, lua, markdown, matlab, mojo, nix, nu, objc, ocaml,
pascal, perl, php, progress, prolog, ps1, pyrex, python, r, racket, raku, ruby, rust, sas,
scala, scheme, scilab, sh, sml, solidity, sql, st, stata, swift, systemverilog, tcl,
typescript, uc, vb, verilog, vhdl, yaml, zig

**Nicht gefaerbt** wird alles andere, zum Beispiel:

- Vim script und Fortran
- JSON mit Kommentaren (jsonc), zum Beispiel `tsconfig.json` und die `settings.json` in den
  Benutzereinstellungen von VS Code
- Objective-C++ (`.mm`, und `.h`-Dateien, in denen eine Zeile mit `@interface`, `@class` oder
  `@end` beginnt)
- zsh, csh, tcsh

Welche Regeln gelten, entscheidet wie in Vim 9.2 der Dateiname (`dateitypen.json`) und bei
mehrdeutigen Endungen wie `.h .m .pl .v .bas .p` der Inhalt (`erkennen.js`). Dateien ohne
passenden Namen werden an der ersten Zeile `#!...` erkannt, ungespeicherte Dateien an der in
VS Code gewaehlten Sprache. Unter Windows und macOS zaehlt Gross-/Kleinschreibung nicht.

Fuer Shell gibt es wie in Vim drei Regelsaetze: bash, Korn-Shell und POSIX. Es entscheidet die
erste Zeile, sonst der Dateiname (`.bashrc`, `*.bash`, `*.ksh` ...). `#!/bin/sh` und Dateien
ohne Angabe gelten als POSIX-Shell, wie in Vim unter Windows.

## Wie genau?

Verglichen mit Vim 9.2 (Patches 1-858) unter Linux, ohne eigene Einstellungen:

- 80 Testdateien aus `test/` in allen 34 Themes: keine Abweichung.
- eine Stichprobe von 438 C- und C++-Dateien und Headern ohne Abweichung.
- 322 weitere Dateien in 39 Sprachen (Vims Syntax-Tests und Dateien des Systems): 320 gleich,
  die zwei anderen sind HTML-Vorlagen.

Mehr dazu in [MESSUNGEN.md](MESSUNGEN.md). **Eine Testdatei je Sprache prueft nicht jedes
Sprachkonstrukt.** Bei anderem Code sind Abweichungen zu erwarten.

Bekannte Abweichungen:

- COBOL: Zeilen, die ueber Spalte 72 hinausgehen, koennen anders aussehen. Das freie Format
  kennen Vims Regeln nicht; es erscheint wie in gVim zu grossen Teilen als Fehler.
- Die Varianten der Korn-Shell (ksh88, ksh93, mksh) werden alle gleich gefaerbt.
- Vorlagen in HTML (Angular, Django) werden nur als HTML gefaerbt.
- Nach einer Zeile mit mehr als 3000 Zeichen kann die folgende Zeile anders aussehen.

## Installieren

Braucht Node.js ab Version 20 und beim ersten Mal Internet (laedt `@vscode/vsce`).

    bash werkzeuge/vsix.sh                                   # baut vim-semantic-<version>.vsix
    code --install-extension vim-semantic-0.2.1.vsix --force
    codium --install-extension vim-semantic-0.2.1.vsix --force      # fuer VSCodium

Danach VS Code bzw. VSCodium neu starten und ein "VimSem ..."-Farbschema waehlen.

Empfohlen, weil Vim Klammern nicht nach Tiefe faerbt:

    "editor.bracketPairColorization.enabled": false

Entfernen: `code --uninstall-extension r11s.vim-semantic` (VSCodium: `codium` statt `code`)

## Einstellungen

| Einstellung | Vorgabe | Bedeutung |
|---|---|---|
| `vimHighlight.backgroundGroups` | `["Todo", "Error", "Constant"]` | Gruppen mit Hintergrund |
| `vimHighlight.logFile` | `false` | Protokoll in `protokoll.txt` im Erweiterungsordner |

Fehlersuche: Ansicht "Ausgabe", Kanal "VimSem".

## Neue Sprache anfragen

Fehlt eine Sprache, oder wird eine nicht wie in Vim gefaerbt? Dann bitte ein
[Issue](https://github.com/r11s/vim-semantic/issues) eroeffnen, mit dem Namen der Sprache, der
Dateiendung und wenn moeglich einem kleinen Beispiel. Vielleicht wird sie in einem der
naechsten Releases aufgenommen. Voraussetzung: Vim hat fuer die Sprache eine Syntax.

## Grenzen

- Hintergruende nur fuer die eingestellten Gruppen. Semantic Tokens kennen keinen Hintergrund,
  deshalb setzt die Erweiterung dafuer Decorations.
- Cursorzeile, Zeilennummern, Auswahl und Suchtreffer haben die Farben von VS Code.
- Bei jeder Aenderung wird die ganze Datei neu berechnet. Bei 5000 Zeilen dauert das meist
  unter 0,5 Sekunden, bei einzelnen Sprachen (JSON, Nushell) gut 1 Sekunde (gemessen unter
  Linux).
- Syntax wird immer ab Dateianfang berechnet (wie `syntax sync fromstart`).
- Ohne vimrc und Plugins.
- Andere Semantic-Token-Anbieter (etwa fuer TypeScript) koennen Vorrang bekommen.

## Entwickeln

Vim 9 braucht nur, wer Themes oder Daten erzeugt oder misst.

Testfenster ohne Installation:

    code --extensionDevelopmentPath=/pfad/zu/vim-semantic

Themes erzeugen (nutzt dein Vim; `VIM_PATH` setzt ein anderes):

    node generate.js elflord dark       # ein Theme hinzufuegen oder erneuern
    bash werkzeuge/themes.sh            # alle vorhandenen neu erzeugen

Messen:

    node measure.js blue                # bei hell und dunkel: node measure.js <name> light|dark

Vergleicht je Zeichen (ohne Leerraum) Farbe, Stil und Hintergrund: Soll aus `vim/reference.vim`
(Vim), Ist aus dem Faerber der Erweiterung (`faerben.js`) und der Theme-Datei. Abweichungen stehen in
`messung/<name>-<light|dark>.txt`. Rechnerisch: Was VS Code tatsaechlich anzeigt, wird damit
nicht geprueft.

| Ordner | Inhalt |
|---|---|
| `themes/` | die erzeugten VS-Code-Themes |
| `vim/` | Vim-Skripte |
| `test/` | Testprogramme, siehe [test/README.md](test/README.md) |
| `syntaxdaten/` | Faerberegeln von Vim je Sprache, siehe [syntaxdaten/README.md](syntaxdaten/README.md) |
| `schemata/` | wo ein Farbschema eine Gruppe anders zuordnet |
| `werkzeuge/` | Skripte zum Bauen, Erzeugen und Pruefen |

Mit Vim vergleichen und Daten erzeugen:

    node werkzeuge/ohne-vim-messen.js auto datei...   # mit SCHEMA=blue BG=dark fuer ein anderes
    node werkzeuge/schema-gruppen.js cpp              # schemata/cpp.json neu erzeugen
    node werkzeuge/schema-gruppen.js sh test/08_shell.sh   # sh braucht eine Beispieldatei
    node werkzeuge/schema-gruppen.js sh-posix datei         # Datei mit "#!/bin/sh"; sh-ksh: "#!/bin/ksh"
    node werkzeuge/dateitypen.js                      # dateitypen.json (braucht VIMRUNTIME)

Kurzbefehle: [SPICKZETTEL.md](SPICKZETTEL.md).

## Lizenz

VimSem steht unter der Vim-Lizenz, siehe [LICENSE](LICENSE).

Themes, Syntaxdaten und Dateityp-Erkennung sind aus Dateien von [Vim](https://github.com/vim/vim) abgeleitet und
dabei veraendert. Die Angaben zu diesen Dateien, auch zu solchen mit eigener Lizenz, stehen in
[LIZENZEN.md](LIZENZEN.md). Neu erzeugen: `werkzeuge/lizenzen.js`.

Kontakt (Abschnitt II 2a der Vim-Lizenz): <https://github.com/r11s/vim-semantic/issues>
