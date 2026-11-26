#!/usr/bin/env bash
# Baut das Paket zum Installieren, z. B. vim-semantic-0.1.0.vsix
#   bash werkzeuge/vsix.sh
# Was hineinkommt, steht in .vscodeignore. Die Version steht in generate.js.
set -euo pipefail
cd "$(dirname "$0")/.."

datei=$(node -p 'const p = require("./package.json"); `${p.name}-${p.version}.vsix`')

# --skip-license: das Projekt hat noch keine Lizenzdatei
npx --yes @vscode/vsce@3.9.2 package --skip-license --out "$datei"

echo "Installieren: code --install-extension $datei --force"
