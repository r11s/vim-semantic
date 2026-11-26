#!/usr/bin/env bash
# Erzeugt alle vorhandenen Vim-Themes neu, z. B. nach neuen Sprachen oder neuem Vim.
#   bash werkzeuge/themes.sh
# Ein weiteres Theme einmalig anlegen: node generate.js <schema> <light|dark>
set -euo pipefail
cd "$(dirname "$0")/.."

# Welche Themes es gibt, steht in scheme.json
liste=$(node -e 'for (const t of Object.values(require("./scheme.json").themes)) console.log(t.scheme, t.background)')

while read -r schema hintergrund; do
  echo "== $schema ($hintergrund)"
  node generate.js "$schema" "$hintergrund" </dev/null
done <<< "$liste"

echo "Fertig. Das VS-Code-Testfenster neu starten."
