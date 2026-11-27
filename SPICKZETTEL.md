# Kochbuch vim-semantic

Alles in **Git Bash**, im Ordner `~/work/vim-semantic`.

## Testfenster starten

    code --extensionDevelopmentPath="$(pwd -W)"

## Theme erzeugen

    node generate.js blue              # oder: <name> light|dark

Danach das Testfenster neu starten.

## vsix bauen und installieren

    bash werkzeuge/vsix.sh
    code --install-extension vim-semantic-1.0.0.vsix --force
    codium --install-extension vim-semantic-1.0.0.vsix --force

Danach VS Code bzw. VSCodium neu starten. Wieder entfernen:

    code --uninstall-extension r11s.vim-semantic
    codium --uninstall-extension r11s.vim-semantic

## Messen

    node measure.js blue               # Details in messung/
    bash werkzeuge/themes.sh           # vorher: alle Themes neu erzeugen

## Färben mit Vim vergleichen

    node werkzeuge/ohne-vim-messen.js auto test/[0-9]*

Mit dem Vim aus gVim:

    VIM_PATH="C:/Program Files/Vim/vim92/vim.exe" node werkzeuge/ohne-vim-messen.js auto test/[0-9]*

## Syntaxdaten prüfen

    node werkzeuge/syntaxdaten-pruefen.js      # Abweichungen in temp/unterschiede.txt

Mit dem Vim aus gVim:

    VIM_PATH="C:/Program Files/Vim/vim92/vim.exe" node werkzeuge/syntaxdaten-pruefen.js

Neu erzeugen geht nur mit dem ergänzten Vim, siehe `syntaxdaten/README.md`.

## Alles ist einfarbig

- "VimSem ..."-Farbschema wählen: Strg+K, Strg+T
- In settings.json: `"editor.semanticHighlighting.enabled": true`
- Ansicht "Ausgabe", Kanal "VimSem" ansehen
- Für `protokoll.txt`: `"vimsem.logFile": true`
- Steht im Kanal "no syntax rules for this file": Der Dateityp wird nicht gefärbt, siehe README

## Woher kommt eine Farbe?

Strg+Umschalt+P → "Developer: Inspect Editor Tokens and Scopes"

## Änderungen sichern und hochladen

    git status
    git add .
    git commit -m "Nachricht"
    git push

## Neuesten Stand holen

    git pull

## Push wird abgelehnt

    git pull --rebase
    git push

## Auf einem anderen Rechner einrichten

    git clone https://github.com/r11s/vim-semantic.git

## Neues Repository auf GitHub anlegen

Einmal pro Rechner anmelden:

    gh auth login

Im Projektordner:

    git init
    git add .
    git commit -m "Erster Stand"
    gh repo create <name> --private --source=. --remote=origin --push

### Beispiel: Projekt `farbtest`

    cd ~/work/farbtest
    git init
    git add .
    git commit -m "Erster Stand"
    gh repo create farbtest --private --source=. --remote=origin --push
