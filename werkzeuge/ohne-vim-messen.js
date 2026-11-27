'use strict';
// Faerbt Dateien einmal ohne Vim (faerben.js) und einmal mit Vim und vergleicht die Gruppe
// jedes Zeichens.
//   node werkzeuge/ohne-vim-messen.js c datei...     (Typ aus syntaxdaten)
//   node werkzeuge/ohne-vim-messen.js auto datei...  (Typ wie in der Erweiterung, nach Name
//                                                     und bei ".h" nach Inhalt)
//   SCHEMA=blue BG=dark ... prueft mit einem anderen Farbschema
const fs = require('fs');
const path = require('path');
const { highlight } = require('../vim');
const { highlighter, loadData } = require('../faerben');
const { typeFor } = require('../erkennen');

const perChar = (tokens, lines) => {
  const map = new Map();
  for (const t of tokens) {
    for (let i = t.start; i < t.start + t.length; i++) {
      if (/\S/.test(lines[t.line]?.[i] ?? '')) map.set(`${t.line}:${i}`, t.type);
    }
  }
  return map;
};

async function main() {
  const [wanted, ...files] = process.argv.slice(2);
  if (!files.length) throw new Error('Aufruf: node werkzeuge/ohne-vim-messen.js <typ> <datei>...');
  const engines = new Map();
  const engineFor = (type) => {
    if (!engines.has(type)) {
      const engine = highlighter(loadData(type));
      if (engine.skipped.length) console.log(`${type}: ${engine.skipped.length} Regeln nicht verstanden`);
      engines.set(type, engine);
    }
    return engines.get(type);
  };
  const types = {};
  const total = { chars: 0, wrong: 0, files: 0, bad: 0, own: 0, vim: 0, lines: 0 };
  for (const file of files) {
    const text = fs.readFileSync(file, 'utf8');
    const lines = text.split(/\r?\n/);
    const type = wanted === 'auto' ? typeFor(file, text) : wanted;
    if (!type) { console.log(`${path.basename(file)}: nicht freigegeben, uebersprungen`); continue; }
    types[type] = (types[type] || 0) + 1;
    const engine = engineFor(type);
    let time = Date.now();
    const got = perChar(engine.highlight(text, {
      scheme: process.env.SCHEMA || 'default', background: process.env.BG || 'light',
    }), lines);
    total.own += Date.now() - time;
    time = Date.now();
    const want = perChar(await highlight({
      vimPath: process.env.VIM_PATH || 'vim', text, fileName: file, filetype: type.replace(/^(sh|make|diff|tex)-.*/, '$1'),
      scheme: process.env.SCHEMA || 'default', background: process.env.BG || 'light',
    }), lines);
    total.vim += Date.now() - time;
    const keys = new Set([...want.keys(), ...got.keys()]);
    const wrong = [...keys].filter((k) => want.get(k) !== got.get(k));
    total.files++;
    total.lines += lines.length;
    total.chars += lines.join('').replace(/\s/g, '').length;
    total.wrong += wrong.length;
    if (wrong.length) {
      total.bad++;
      wrong.sort((a, b) => a.split(':')[0] - b.split(':')[0] || a.split(':')[1] - b.split(':')[1]);
      const [line, column] = wrong[0].split(':').map(Number);
      console.log(`${path.basename(file)}: ${wrong.length} anders; Zeile ${line + 1}, Spalte ${column + 1}: ` +
        `Vim ${want.get(wrong[0]) ?? '-'}, ohne Vim ${got.get(wrong[0]) ?? '-'} | ${lines[line].trim().slice(0, 90)}`);
    }
  }
  console.log(`${total.files} Dateien, ${total.lines} Zeilen, ${total.chars} Zeichen: ${total.wrong} anders ` +
    `in ${total.bad} Dateien. Zeit ohne Vim ${total.own} ms, mit Vim ${total.vim} ms; ` +
    Object.entries(types).map(([t, n]) => `${n}x ${t}`).join(', '));
}

main().catch((error) => { console.error(error.stack); process.exit(1); });
