'use strict';
// Schreibt LIZENZEN.md: die Kopfangaben aller Vim-Dateien, aus denen syntaxdaten und
// themes abgeleitet sind, woertlich uebernommen.
//   VIMRUNTIME=/pfad/zu/vim92 node werkzeuge/lizenzen.js
// VIMRUNTIME muss zur selben Vim-Version gehoeren wie die Daten.
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const RUNTIME = process.env.VIMRUNTIME;
if (!RUNTIME) throw new Error('VIMRUNTIME ist nicht gesetzt.');

const json = (...parts) => JSON.parse(fs.readFileSync(path.join(ROOT, ...parts), 'utf8'));
const files = (dir) => fs.readdirSync(path.join(ROOT, dir)).filter((f) => f.endsWith('.json'));

const sources = new Set();
for (const name of files('syntaxdaten')) {
  for (const [where] of json('syntaxdaten', name).befehle) {
    const file = where.slice(0, where.lastIndexOf(':'));
    if (file.startsWith('syntax/')) sources.add(file);
  }
}
for (const name of files('themes')) sources.add(`colors/${json('themes', name).vimScheme}.vim`);

// Zusammenhaengende Kommentarbloecke einer Datei; der erste ist der Dateikopf
function blocks(lines) {
  const result = [];
  let current = null;
  let head = true;
  for (const line of lines) {
    const comment = /^\s*"/.test(line);
    if (comment || (head && !line.trim())) {
      if (!current) result.push(current = { head, lines: [] });
      current.lines.push(line);
    } else {
      current = null;
      head = false;
    }
  }
  return result;
}

const NOTICE = /copyright|permission is hereby|\blicen[cs]e\b/i;
const entry = (file) => {
  const lines = fs.readFileSync(path.join(RUNTIME, file), 'utf8').split(/\r?\n/);
  const wanted = blocks(lines).filter((b) => b.head || b.lines.some((l) => NOTICE.test(l)));
  const text = wanted.map((b) => b.lines.join('\n').trim()).filter(Boolean).join('\n\n[...]\n\n');
  return [`### ${file}`, '', '~~~~text', text || '(ohne Kopfangaben)', '~~~~', ''].join('\n');
};

const group = (title, prefix) => [`## ${title}`, '',
  ...[...sources].filter((f) => f.startsWith(prefix)).sort().map(entry)];

fs.writeFileSync(path.join(ROOT, 'LIZENZEN.md'), [
  '# Lizenzangaben', '',
  'VimSem steht unter der Vim-Lizenz (Datei `LICENSE`). Teile sind aus Dateien von Vim 9.2',
  '(Patches 1-858) abgeleitet und dabei veraendert, also umgeformt und neu verpackt:', '',
  '- `themes/`: Farben und Stile aus den Farbschemata (`colors/*.vim`)',
  '- `syntaxdaten/`: ausgefuehrte Regeln aus den Syntaxdateien (`syntax/*.vim`), in der vsix nur C',
  '- `schemata/`: Zuordnung der Gruppen aus Farbschemata und Syntaxdateien',
  '- `werkzeuge/vim-synlog.patch`: Aenderung am Quellcode von Vim, nicht in der vsix', '',
  'Fuer eine Datei mit eigener Lizenz gilt diese. Dateien ohne eigene Lizenzangabe werden mit',
  'Vim verteilt und gelten hier als unter der Vim-Lizenz. Unten stehen ihre Angaben woertlich.', '',
  'Volltexte im Ordner `lizenzen/`, mit Herkunft (abgerufen am 26.11.2026):', '',
  '| Datei in `lizenzen/` | zu | Herkunft |',
  '|---|---|---|',
  ...[
    ['Go-BSD-3-Clause.txt', 'go', 'LICENSE einer Go-Installation'],
    ['vim-go-BSD-3-Clause.txt', 'go', 'https://github.com/fatih/vim-go'],
    ['swift-Apache-2.0.txt', 'swift', 'https://github.com/swiftlang/swift'],
    ['vim-nix-MIT.txt', 'nix', 'https://github.com/LnL7/vim-nix'],
    ['nushell-syntax-vim-MIT.txt', 'nu', 'https://github.com/elkasztano/nushell-syntax-vim'],
    ['elm-vim-BSD-3-Clause.txt', 'elm', 'https://github.com/ElmCast/elm-vim'],
    ['rust.vim-MIT.txt', 'rust (wahlweise)', 'https://github.com/rust-lang/rust.vim'],
    ['rust.vim-Apache-2.0.txt', 'rust (wahlweise)', 'https://github.com/rust-lang/rust.vim'],
  ].map(([file, type, source]) => `| \`${file}\` | \`syntax/${type.split(' ')[0]}.vim\`${type.includes(' ') ? ' (wahlweise)' : ''} | ${source} |`), '',
  'Der Volltext der MIT-Lizenz zu `syntax/json.vim` steht unten bei dieser Datei.', '',
  'Nicht geprueft ist, ob die Ursprungs-Repositorys weiterer Dateien oder Farbschemata eigene',
  'Lizenzen haben, die in der Datei selbst nicht genannt sind.', '',
  ...group('Farbschemata', 'colors/'),
  ...group('Syntaxdateien', 'syntax/'),
].join('\n'));
console.log(`LIZENZEN.md: ${sources.size} Dateien`);
