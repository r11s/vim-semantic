'use strict';
// Sammelt je Dateityp der Testdateien, womit Vim faerbt, in den Ordner syntaxdaten.
//   VIM_PATH=/pfad/zum/ergaenzten/vim node werkzeuge/syntaxdaten.js
// Braucht ein Vim mit vim-synlog.patch: nur so kommen die Befehle in ausgefuehrter
// Reihenfolge heraus. Mit einem normalen Vim bricht das Skript ab, ohne etwas zu aendern.
//   Vim-Quellcode v9.2.0858: git apply vim-synlog.patch, dann wie gewohnt bauen
const fs = require('fs');
const os = require('os');
const path = require('path');
const { runVim } = require('../vim');

const ROOT = path.join(__dirname, '..');
const TESTDIR = path.join(ROOT, 'test');
const TARGET = path.join(ROOT, 'syntaxdaten');
const VIM = process.env.VIM_PATH || 'vim';
// Unterstuetzte Sprachen ohne Testdatei: Regeln aus einer leeren Datei, ohne Gegenprobe
const EXTRA = ['json', 'html', 'css', 'markdown', 'yaml'];
// Bei manchen Typen waehlt Vim die Regeln nach Dateiname oder Inhalt. Die Testdatei liefert
// die eine Art (sh.json: bash, make.json: GNU, diff.json: unified), die anderen entstehen aus
// einer kurzen Datei: Name der Regeln -> [Dateiname, Inhalt]
const VARIANTS = {
  'sh-posix': ['beispiel.sh', '#!/bin/sh'],
  'sh-ksh': ['beispiel.sh', '#!/bin/ksh'],
  'make-bsd': ['BSDmakefile', '# BSD'],
  'make-microsoft': ['beispiel.mk', '!include regeln.mak'],
  'diff-context': ['beispiel.diff', '*** alt\n--- neu'],
};
// Gleicher Dateityp, nach der Endung andere Regeln: tex.vim kennt "@" in Stildateien als
// Buchstaben und hat fuer ".dtx" eigene Kommentare
const BY_EXTENSION = [[/\.sty$/, 'tex', 'tex-sty'], [/\.dtx$/, 'tex', 'tex-dtx']];
const slash = (file) => file.replace(/\\/g, '/');

// Reine Abfragen und An-/Abschalten sind keine Regeln
const noRule = (command) => /^(list\b.*|on|off|enable|manual|reset|case|conceal|foldlevel|iskeyword|spell|sync)\s*$/.test(command);

function readCommands(log, runtime) {
  const rows = fs.readFileSync(log, 'utf8').split('\n');
  const from = rows.indexOf('--start');
  const to = rows.indexOf('--end');
  let commands = [];
  let depth = 0; // innerhalb von "syntax include"
  for (const row of rows.slice(from + 1, to)) {
    const [script, line, ...rest] = row.split('\t');
    const command = rest.join('\t').trim();
    if (!command || noRule(command)) continue;
    if (command === 'include-end') depth--;
    // "syntax clear" ohne Namen verwirft alles Bisherige
    if (command === 'clear' && depth === 0) { commands = []; continue; }
    // Nur Pfade innerhalb von Vim bzw. diesem Projekt: keine Pfade des Rechners in den Daten
    const full = slash(script);
    const source = full.includes('/runtime/') ? full.slice(full.lastIndexOf('/runtime/') + 9)
      : full.startsWith(slash(ROOT) + '/') ? full.slice(slash(ROOT).length + 1)
        : full.replace(slash(runtime) + '/', '');
    commands.push([`${source}:${line}`, command]);
    if (/^include\s/.test(command)) depth++;
  }
  // Nichts zwischen den Marken: dieses Vim hat die Ergaenzung nicht
  if (to === from + 1) {
    throw new Error('Dieses Vim schreibt keine Befehle mit (werkzeuge/vim-synlog.patch fehlt). Nichts geaendert.');
  }
  return commands;
}

async function collect(file, filetype) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'vim-syntax-'));
  try {
    const output = path.join(dir, 'data.json');
    const log = path.join(dir, 'synlog');
    await runVim(VIM, 'syntax-data.vim', {
      VH_IN: file ? path.resolve(TESTDIR, file) : '', VH_OUT: output,
      VH_FILETYPE: filetype || '', VH_SYNLOG: slash(log),
    });
    const data = JSON.parse(fs.readFileSync(output, 'utf8'));
    data.commands = readCommands(log, process.env.VIMRUNTIME || '');
    return data;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

// Alle Gruppen, die in den Regeln vorkommen, samt ihrer Verweiskette
function groupsOf(data) {
  const names = new Set();
  for (const row of data.list) {
    const head = /^(\S+)\s+(xxx\s|cluster=)/.exec(row);
    if (head && head[2] !== 'cluster=') names.add(head[1]);
    for (const m of row.matchAll(/matchgroup=(\S+)/g)) names.add(m[1]);
  }
  for (const [, command] of data.commands) {
    const item = /^(keyword|match|region)\s+(\S+)/.exec(command);
    if (item) names.add(item[2]);
    for (const m of command.matchAll(/matchgroup=(\w+)/g)) names.add(m[1]);
  }
  const groups = {};
  const add = (name) => {
    if (name === 'NONE' || name in groups || !(name in data.links)) return;
    groups[name] = data.links[name] || null;
    if (data.links[name]) add(data.links[name]);
  };
  [...names].sort().forEach(add);
  return Object.fromEntries(Object.entries(groups).sort());
}

// Ein Eintrag je Zeile, damit die Dateien lesbar und vergleichbar bleiben
const serialize = (value) => '{\n' + Object.entries(value).map(([key, v]) => {
  if (Array.isArray(v) && v.length) return `${JSON.stringify(key)}: [\n${v.map((x) => ' ' + JSON.stringify(x)).join(',\n')}\n]`;
  if (v && typeof v === 'object' && !Array.isArray(v)) {
    return `${JSON.stringify(key)}: {\n${Object.entries(v).map(([k, x]) => ` ${JSON.stringify(k)}: ${JSON.stringify(x)}`).join(',\n')}\n}`;
  }
  return `${JSON.stringify(key)}: ${JSON.stringify(v)}`;
}).join(',\n') + '\n}\n';

async function main() {
  const files = fs.readdirSync(TESTDIR)
    .filter((f) => /^\d{2,3}_/.test(f) && !/\.(exe|o|swp)$/.test(f)).sort();
  const written = new Map(); // Name -> Regeln als Text
  const overview = [];
  for (const file of files) {
    const data = await collect(file);
    let type = data.filetype;
    if (!type) { console.log(`${file}: kein Dateityp`); continue; }
    type = BY_EXTENSION.find(([end, of]) => of === type && end.test(file))?.[2] || type;
    const rules = JSON.stringify(data.commands.map((c) => c[1]));
    const same = [...written].find(([name, text]) => name.split('~')[0] === type && text === rules);
    if (same) {
      overview.find((o) => o.name === same[0]).files.push(file);
      continue;
    }
    // Gleicher Dateityp, aber andere Regeln: eigene Datei
    const name = written.has(type) ? `${type}~${file.replace(/\.[^.]*$/, '')}` : type;
    written.set(name, rules);
    // Dieselbe Sprache ohne Inhalt: haengen die Regeln vom Text ab?
    const empty = await collect(null, data.filetype);
    const emptyRules = JSON.stringify(empty.commands.map((c) => c[1]));
    overview.push({ name, files: [file], data, contentDependent: emptyRules !== rules });
    console.log(`${name}: ${data.commands.length} Befehle`);
  }

  for (const type of EXTRA.filter((t) => !written.has(t))) {
    const data = await collect(null, type);
    overview.push({ name: type, files: [], data, contentDependent: null });
    console.log(`${type}: ${data.commands.length} Befehle (ohne Testdatei)`);
  }

  for (const [name, [fileName, content]] of Object.entries(VARIANTS)) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'vim-variant-'));
    try {
      const sample = path.join(dir, fileName);
      fs.writeFileSync(sample, `${content}\n`);
      const data = await collect(sample);
      overview.push({ name, files: [], data, contentDependent: true });
      console.log(`${name}: ${data.commands.length} Befehle (${fileName})`);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }

  fs.mkdirSync(TARGET, { recursive: true });
  for (const entry of overview) {
    const { data } = entry;
    fs.writeFileSync(path.join(TARGET, `${entry.name}.json`), serialize({
      dateityp: data.filetype,
      vim: data.version,
      testdateien: entry.files,
      inhaltsabhaengig: entry.contentDependent,
      iskeyword: data.iskeyword,
      syntaxIskeyword: data.syntaxIskeyword,
      gruppen: groupsOf(data),
      befehle: data.commands,
      liste: data.list,
    }));
  }

  const count = (data, word) => (data.commands).filter((c) => c[1].startsWith(word + ' ')).length;
  const words = ['keyword', 'match', 'region', 'cluster', 'include'];
  fs.writeFileSync(path.join(TARGET, 'README.md'), [
    '# Syntaxdaten', '',
    'Erzeugt mit `node werkzeuge/syntaxdaten.js`, Gegenprobe mit `node werkzeuge/syntaxdaten-pruefen.js`.',
    'Nicht von Hand aendern. Abgeleitet aus den Syntaxdateien von Vim; Lizenzen in ../LIZENZEN.md.', '',
    'Je Datei:', '',
    '- `befehle`: alle ausgefuehrten `syntax`-Befehle in ihrer Reihenfolge, als [Herkunft, Befehl]',
    '- `gruppen`: Gruppe und die Gruppe, auf die sie verweist (`null` = keine)',
    '- `liste`: Ausgabe von `:syntax list` (nach Gruppen sortiert, ohne Reihenfolge und Gross/Klein)',
    '- `iskeyword`, `syntaxIskeyword`: was als Wort gilt',
    '- `inhaltsabhaengig`: die Regeln sind anders als bei einer leeren Datei desselben Typs', '',
    '`name~testdatei.json`: gleicher Dateityp, aber andere Regeln als in `name.json`.',
    'Aus einer leeren Datei erzeugt und von der Gegenprobe nicht erfasst: ' +
      EXTRA.join(', ') + '.',
    '`sh.json` gilt fuer bash, `sh-posix.json` fuer `#!/bin/sh` und dash, `sh-ksh.json` fuer die Korn-Shell.',
    '`make.json` gilt fuer GNU make, daneben `make-bsd.json` und `make-microsoft.json`.',
    '`diff.json` gilt fuer unified diff, `diff-context.json` fuer die anderen Formate.',
    '`tex.json` gilt fuer LaTeX, `tex-sty.json` fuer Stildateien wie `.sty` und `.cls`, `tex-dtx.json` fuer `.dtx`.',
    'Zum Erzeugen ist ein Vim mit `werkzeuge/vim-synlog.patch` noetig.', '',
    `| Datei | ${words.join(' | ')} | inhaltsabhaengig | Testdateien |`,
    `|---|${words.map(() => '--:|').join('')}---|---|`,
    ...overview.sort((a, b) => a.name.localeCompare(b.name)).map((e) =>
      `| ${e.name} | ${words.map((w) => count(e.data, w)).join(' | ')} | ${e.contentDependent ? 'ja' : ''} | ${e.files.join(', ')} |`),
    '',
  ].join('\n'));
  console.log(`\n${overview.length} Dateien in syntaxdaten, ${files.length} Testdateien`);
}

main().catch((error) => { console.error(error.message); process.exit(1); });
