# Spickzettel vim-semantic

Alle Befehle in **Git Bash**. Zuerst in den Ordner wechseln:

    cd ~/work/vim-semantic

## Starten

    code --extensionDevelopmentPath="$(pwd -W)"

Vorher das alte Testfenster schließen.

## Themes

    node generate.js default light
    node generate.js elflord dark
    node generate.js blue
    node generate.js <name> [light|dark]    # weiteres Theme

Danach das Testfenster neu starten.

## Messen

    node measure.js default
    node measure.js elflord
    node measure.js blue

Abweichungen im Einzelnen stehen in `messung/`.

## Tasten in VS Code

| Taste / Befehl | Wirkung |
|---|---|
| Strg+K, Strg+T | Farbschema wählen |
| Strg+Umschalt+P → "Developer: Inspect Editor Tokens and Scopes" | Woher kommt diese Farbe? |
| Strg+Umschalt+P → "Preferences: Open User Settings (JSON)" | settings.json öffnen |
| Strg+# | Zeile aus-/einkommentieren |

## settings.json

    "editor.semanticHighlighting.enabled": true,
    "editor.bracketPairColorization.enabled": false,
    "vimHighlight.backgroundGroups": ["Todo", "Error"],   // nur zum Abweichen von der Vorgabe
    "vimHighlight.vimPath": "vim"                         // nur falls Vim nicht gefunden wird

## Wenn alles nur einfarbig ist

1. Ist `editor.semanticHighlighting.enabled` auf `true`?
2. Ist ein "Vim ..."-Farbschema gewählt?
3. `protokoll.txt` ansehen (oder Ausgabe → "Vim Highlight").

## Git

    git status                 # was hat sich geändert?
    git diff                   # Änderungen ansehen (Ende mit q)
    git add .                  # alles vormerken, auch neue Dateien
    git commit -m "Nachricht"  # festhalten
    git log --oneline          # Verlauf

`git commit -am` nimmt neue Dateien **nicht** mit, dafür erst `git add .`.
