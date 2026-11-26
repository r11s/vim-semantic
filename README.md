# vim-semantic (VimSem)

Die Farbschemata von Vim im Editor von VS Code, so wie in Vim. Vim ermittelt im Hintergrund
die Highlight-Gruppen, VS Code zeigt sie als Semantic Tokens an. Enthalten sind 34 Themes
"VimSem ..." zu den Farbschemata von Vim 9.2.

Es geht nur um die Darstellung im Editor, nicht um das Verhalten von Vim.

## Voraussetzung

Vim 9 mit Syntax-Unterstuetzung (nicht vim-tiny) auf demselben Rechner. Ohne Vim wird nichts
gefaerbt.

## Installieren

Braucht Node.js ab Version 20 und beim ersten Mal Internet (laedt `@vscode/vsce`).

    bash werkzeuge/vsix.sh                                   # baut vim-semantic-<version>.vsix
    code --install-extension vim-semantic-0.1.0.vsix --force

Danach VS Code neu starten und ein "VimSem ..."-Farbschema waehlen.

Findet VS Code kein Vim, in der settings.json den vollen Pfad zur `vim.exe` angeben, z. B. fuer
das Vim aus Git oder fuer gVim:

    "vimHighlight.vimPath": "C:\\Program Files\\Git\\usr\\bin\\vim.exe"
    "vimHighlight.vimPath": "C:\\Program Files\\Vim\\vim92\\vim.exe"

Empfohlen, weil Vim Klammern nicht nach Tiefe faerbt:

    "editor.bracketPairColorization.enabled": false

Entfernen: `code --uninstall-extension r11s.vim-semantic`

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
- Vim startet bei jeder Aktualisierung neu; grosse Dateien sind langsam.
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
| `werkzeuge/` | Skripte zum Bauen, Erzeugen und Pruefen |

Die Syntaxdaten benutzt die Erweiterung noch nicht. Sie sind die Grundlage dafuer, spaeter
ohne installiertes Vim zu faerben. Kurzbefehle: [SPICKZETTEL.md](SPICKZETTEL.md).

## Lizenz

VimSem steht unter der Vim-Lizenz, siehe [LICENSE](LICENSE).

Themes und Syntaxdaten sind aus Dateien von [Vim](https://github.com/vim/vim) abgeleitet und
dabei veraendert. Die Angaben zu diesen Dateien, auch zu solchen mit eigener Lizenz, stehen in
[LIZENZEN.md](LIZENZEN.md). Neu erzeugen: `werkzeuge/lizenzen.js`.

Kontakt (Abschnitt II 2a der Vim-Lizenz): <https://github.com/r11s/vim-semantic/issues>
