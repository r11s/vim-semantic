# vim-semantic (VimSem)

Vim ermittelt im Hintergrund die Highlight-Gruppen, VS Code zeigt sie als Semantic Tokens an.

## Starten

Voraussetzung: Vim 9 mit Syntax-Unterstuetzung (nicht vim-tiny).

    node generate.js default light      # nutzt dein Vim; VIM_PATH setzt einen anderen Pfad
    node generate.js elflord dark       # jedes weitere Theme kommt dazu
    code --extensionDevelopmentPath=/pfad/zu/vim-semantic

Im neuen Fenster eines der "VimSem ..."-Farbschemata waehlen.

In der settings.json:

    "editor.bracketPairColorization.enabled": false

Unter Windows ggf. "vimHighlight.vimPath" auf vim.exe setzen.

## Installieren

Braucht Node.js ab Version 20 und beim ersten Mal Internet (laedt `@vscode/vsce`).

    bash werkzeuge/vsix.sh                                   # baut vim-semantic-<version>.vsix
    code --install-extension vim-semantic-0.1.0.vsix --force

Danach VS Code neu starten und ein "VimSem ..."-Farbschema waehlen. Findet VS Code kein Vim,
in der settings.json den vollen Pfad angeben, z. B. fuer das Vim aus Git:

    "vimHighlight.vimPath": "C:\\Program Files\\Git\\usr\\bin\\vim.exe"

Fehlersuche: Ansicht "Ausgabe", Kanal "VimSem". Mit `"vimHighlight.logFile": true`
zusaetzlich in `protokoll.txt` im Erweiterungsordner.

Entfernen: `code --uninstall-extension r11s.vim-semantic`

## Grenzen

- Hintergruende nur fuer die eingestellten Gruppen (siehe unten).
- Vim startet bei jeder Aktualisierung neu; grosse Dateien sind langsam.
- Syntax wird immer ab Dateianfang berechnet (`syntax sync fromstart`).
- Ohne vimrc und Plugins.
- Andere Semantic-Token-Anbieter (etwa fuer TypeScript) koennen Vorrang bekommen.

## Hintergruende

Semantic Tokens kennen keinen Hintergrund, deshalb setzt die Erweiterung Decorations.
Welche Gruppen hinterlegt werden, steht in der Einstellung (Vorgabe Todo, Error und Constant):

    "vimHighlight.backgroundGroups": ["Todo", "Error", "Constant"]

Nach einem Update der Erweiterung alle Themes mit `generate.js` neu erzeugen.

## Messen

    node measure.js blue            # je Theme; bei hell und dunkel: node measure.js <name> light|dark

Vergleicht je Zeichen (ohne Leerraum) Farbe, Stil und Hintergrund: Soll aus `vim/reference.vim`,
Ist aus den Tokens der Erweiterung und der Theme-Datei. Testdateien in `test/`,
Abweichungen in `messung/<name>-<light|dark>.txt`.

Rechnerisch: Was VS Code tatsaechlich anzeigt, wird damit nicht geprueft.
