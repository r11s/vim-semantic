# Kochbuch vim-semantic

Alles in **Git Bash**, im Ordner `~/work/vim-semantic`.

## Testfenster starten

    code --extensionDevelopmentPath="$(pwd -W)"

## Theme erzeugen

    node generate.js blue              # oder: <name> light|dark

Danach das Testfenster neu starten.

## vsix bauen und installieren

    bash werkzeuge/vsix.sh
    code --install-extension vim-semantic-0.1.0.vsix --force

Danach VS Code neu starten. Wieder entfernen:

    code --uninstall-extension r11s.vim-semantic

## Messen

    node measure.js blue               # Details in messung/

## Alles ist einfarbig

- "VimSem ..."-Farbschema wählen: Strg+K, Strg+T
- In settings.json: `"editor.semanticHighlighting.enabled": true`
- Ansicht "Ausgabe", Kanal "VimSem" ansehen
- Für `protokoll.txt`: `"vimHighlight.logFile": true`
- Vim nicht gefunden: `"vimHighlight.vimPath"` setzen (Pfad: `cygpath -w "$(which vim)"`)

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
