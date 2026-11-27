# vim-semantic (VimSem)

Die Farbschemata von Vim im Editor von VS Code, so wie in Vim. Vim ermittelt im Hintergrund
die Highlight-Gruppen, VS Code zeigt sie als Semantic Tokens an. Enthalten sind 34 Themes
"VimSem ..." zu den Farbschemata von Vim 9.2.

Es geht nur um die Darstellung im Editor, nicht um das Verhalten von Vim.

## Voraussetzung

Vim 9 mit Syntax-Unterstuetzung (nicht vim-tiny) auf demselben Rechner. Ohne Vim werden nur
C- und C++-Dateien gefaerbt, siehe unten.

## Versuch: C und C++ ohne Vim

C- und C++-Dateien faerbt die Erweiterung selbst: `faerben.js` wendet die Regeln aus
`syntaxdaten/c.json` und `cpp.json` an, ohne Vim zu starten. Alle anderen Sprachen brauchen
weiterhin Vim. In der Ausgabe "VimSem" steht je Datei "ohne Vim (c)", "ohne Vim (cpp)" oder
"von Vim".

Der Typ wird wie in Vim 9.2 bestimmt:

- `.c` ist C.
- `.cpp .cc .cxx .c++ .hpp .hh .hxx .ipp .tcc .inl .ixx .cppm .moc` sind C++.
- Gross-/Kleinschreibung zaehlt unter Windows und macOS nicht. Unter Linux sind `.C` und
  `.H` C++.
- `.h` ist C++, wenn in den ersten 99 Zeilen eine Zeile mit `class`, `namespace`, `template`
  oder `using` beginnt, sonst C. Beginnt eine mit `@interface`, `@class` oder `@end`
  (Objective-C), faerbt Vim die Datei.

Verglichen mit Vim 9.2 (Patches 1-858) ohne eigene Einstellungen, Zeichen fuer Zeichen:

- 201 C-Dateien aus dem Quelltext von Vim ohne Abweichung.
- 1223 C++-Dateien und Header (libstdc++, Node.js) ohne Abweichung.
- alle 34 Themes mit je 6 C- und C++-Dateien ohne Abweichung.

Bekannte Abweichungen: nach einer Zeile mit mehr als 3000 Zeichen kann die folgende Zeile
anders aussehen, und bei fehlerhaftem Code sind vereinzelte Abweichungen moeglich.

## Installieren

Braucht Node.js ab Version 20 und beim ersten Mal Internet (laedt `@vscode/vsce`).

    bash werkzeuge/vsix.sh                                   # baut vim-semantic-<version>.vsix
    code --install-extension vim-semantic-0.1.0.vsix --force
    codium --install-extension vim-semantic-0.1.0.vsix --force      # fuer VSCodium

Danach VS Code bzw. VSCodium neu starten und ein "VimSem ..."-Farbschema waehlen.

Findet VS Code kein Vim, in der settings.json den vollen Pfad zur `vim.exe` angeben, z. B. fuer
das Vim aus Git oder fuer gVim:

    "vimHighlight.vimPath": "C:\\Program Files\\Git\\usr\\bin\\vim.exe"
    "vimHighlight.vimPath": "C:\\Program Files\\Vim\\vim92\\vim.exe"

Empfohlen, weil Vim Klammern nicht nach Tiefe faerbt:

    "editor.bracketPairColorization.enabled": false

Entfernen: `code --uninstall-extension r11s.vim-semantic` (VSCodium: `codium` statt `code`)

## Einstellungen

| Einstellung | Vorgabe | Bedeutung |
|---|---|---|
| `vimHighlight.vimPath` | `vim` | Pfad zu Vim |
| `vimHighlight.maxLines` | `3000` | groessere Dateien bleiben ungefaerbt |
| `vimHighlight.backgroundGroups` | `["Todo", "Error", "Constant"]` | Gruppen mit Hintergrund |
| `vimHighlight.logFile` | `false` | Protokoll in `protokoll.txt` im Erweiterungsordner |

Fehlersuche: Ansicht "Ausgabe", Kanal "VimSem".

## Sprachen

Gefaerbt werden die Sprachen und Dateiendungen, die in `extension.js` aufgefuehrt sind.
Gemessen ist die Darstellung mit je einem Testprogramm in 75 Sprachen und Dialekten, siehe
[MESSUNGEN.md](MESSUNGEN.md) und [SPRACHEN.md](SPRACHEN.md).

## Neue Sprache anfragen

Fehlt eine Sprache, oder wird eine nicht wie in Vim gefaerbt? Dann bitte ein
[Issue](https://github.com/r11s/vim-semantic/issues) eroeffnen, mit dem Namen der Sprache, der
Dateiendung und wenn moeglich einem kleinen Beispiel. Vielleicht wird sie in einem der
naechsten Releases aufgenommen. Voraussetzung: Vim hat fuer die Sprache eine Syntax.

## Grenzen

- Hintergruende nur fuer die eingestellten Gruppen. Semantic Tokens kennen keinen Hintergrund,
  deshalb setzt die Erweiterung dafuer Decorations.
- Cursorzeile, Zeilennummern, Auswahl und Suchtreffer haben die Farben von VS Code.
- Vim startet bei jeder Aktualisierung neu; grosse Dateien sind langsam (ausser bei C und C++).
- Syntax wird immer ab Dateianfang berechnet (`syntax sync fromstart`).
- Ohne vimrc und Plugins.
- Andere Semantic-Token-Anbieter (etwa fuer TypeScript) koennen Vorrang bekommen.

## Entwickeln

Testfenster ohne Installation:

    code --extensionDevelopmentPath=/pfad/zu/vim-semantic

Themes erzeugen (nutzt dein Vim; `VIM_PATH` setzt ein anderes):

    node generate.js elflord dark       # ein Theme hinzufuegen oder erneuern
    bash werkzeuge/themes.sh            # alle vorhandenen neu erzeugen

Messen:

    node measure.js blue                # bei hell und dunkel: node measure.js <name> light|dark

Vergleicht je Zeichen (ohne Leerraum) Farbe, Stil und Hintergrund: Soll aus `vim/reference.vim`,
Ist aus den Tokens der Erweiterung und der Theme-Datei. Abweichungen stehen in
`messung/<name>-<light|dark>.txt`. Rechnerisch: Was VS Code tatsaechlich anzeigt, wird damit
nicht geprueft.

| Ordner | Inhalt |
|---|---|
| `themes/` | die erzeugten VS-Code-Themes |
| `vim/` | Vim-Skripte |
| `test/` | Testprogramme, siehe [test/README.md](test/README.md) |
| `syntaxdaten/` | Faerberegeln von Vim je Sprache, siehe [syntaxdaten/README.md](syntaxdaten/README.md) |
| `schemata/` | wo ein Farbschema eine Gruppe anders zuordnet (bisher C und C++) |
| `werkzeuge/` | Skripte zum Bauen, Erzeugen und Pruefen |

Die Erweiterung benutzt von den Syntaxdaten bisher C und C++. Faerben ohne Vim pruefen:

    node werkzeuge/ohne-vim-messen.js auto datei...    # mit SCHEMA=blue BG=dark fuer ein anderes
    node werkzeuge/schema-gruppen.js cpp               # schemata/cpp.json neu erzeugen (ebenso c)

Kurzbefehle: [SPICKZETTEL.md](SPICKZETTEL.md).

## Lizenz

VimSem steht unter der Vim-Lizenz, siehe [LICENSE](LICENSE).

Themes und Syntaxdaten sind aus Dateien von [Vim](https://github.com/vim/vim) abgeleitet und
dabei veraendert. Die Angaben zu diesen Dateien, auch zu solchen mit eigener Lizenz, stehen in
[LIZENZEN.md](LIZENZEN.md). Neu erzeugen: `werkzeuge/lizenzen.js`.

Kontakt (Abschnitt II 2a der Vim-Lizenz): <https://github.com/r11s/vim-semantic/issues>
