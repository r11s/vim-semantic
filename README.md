# Vim Highlight (Prototyp)

Vim ermittelt im Hintergrund die Highlight-Gruppen, VS Code zeigt sie als Semantic Tokens an.

## Starten

Voraussetzung: Vim 9 mit Syntax-Unterstuetzung (nicht vim-tiny).

    node generate.js default light      # nutzt dein Vim; VIM_PATH setzt einen anderen Pfad
    node generate.js elflord dark       # jedes weitere Theme kommt dazu
    code --extensionDevelopmentPath=/pfad/zu/vim-highlight

Im neuen Fenster eines der "Vim ..."-Farbschemata waehlen.

In der settings.json:

    "editor.bracketPairColorization.enabled": false

Unter Windows ggf. "vimHighlight.vimPath" auf vim.exe setzen.

## Grenzen

- Hintergruende nur fuer die eingestellten Gruppen (siehe unten).
- Vim startet bei jeder Aktualisierung neu; grosse Dateien sind langsam.
- Syntax wird immer ab Dateianfang berechnet (`syntax sync fromstart`).
- Ohne vimrc und Plugins.
- Andere Semantic-Token-Anbieter (etwa fuer TypeScript) koennen Vorrang bekommen.

## Hintergruende

Semantic Tokens kennen keinen Hintergrund, deshalb setzt die Erweiterung Decorations.
Welche Gruppen hinterlegt werden, steht in der Einstellung (Vorgabe Todo und Error):

    "vimHighlight.backgroundGroups": ["Todo", "Error"]

Nach einem Update der Erweiterung alle Themes mit `generate.js` neu erzeugen.

## Messen

    node measure.js blue            # je Theme; bei hell und dunkel: node measure.js <name> light|dark

Vergleicht je Zeichen (ohne Leerraum) Farbe, Stil und Hintergrund: Soll aus `vim/reference.vim`,
Ist aus den Tokens der Erweiterung und der Theme-Datei. Testdateien in `test/`,
Abweichungen in `messung/<name>-<light|dark>.txt`.

Rechnerisch: Was VS Code tatsaechlich anzeigt, wird damit nicht geprueft.
