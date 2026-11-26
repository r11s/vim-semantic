'use strict';
// Gegenprobe: Reichen die gesammelten Befehle, um wie Vim zu faerben?
// Je Testdatei: Gruppen mit Syntaxdateien (tokens.vim) gegen Gruppen nur aus syntaxdaten.
//   node werkzeuge/syntaxdaten-pruefen.js
const fs = require('fs');
const os = require('os');
const path = require('path');
const { runVim, highlight, tokenType } = require('../vim');

const ROOT = path.join(__dirname, '..');
const VIM = process.env.VIM_PATH || 'vim';
const slash = (file) => file.replace(/\\/g, '/');

// Aus den Daten ein Vim-Skript bauen. "syntax include" bekommt eine eigene Datei,
// weil Vim eingeschlossene Regeln anders behandelt.
function script(data, dir) {
  const stack = [[]];
  const includes = [];
  let count = 0;
  for (const [, command] of data.befehle) {
    if (command === 'include-end') {
      const rows = stack.pop();
      const file = path.join(dir, `include${count++}.vim`);
      fs.writeFileSync(file, rows.join('\n') + '\n');
      const cluster = includes.pop();
      stack.at(-1).push(`syntax include ${cluster}${slash(file)}`);
    } else if (/^include\s/.test(command)) {
      const cluster = /^include\s+(@\S+\s+)/.exec(command);
      includes.push(cluster ? cluster[1] : '');
      stack.push([]);
    } else {
      stack.at(-1).push(`syntax ${command}`);
    }
  }
  return [
    `let &l:iskeyword = ${"'" + data.iskeyword.replace(/'/g, "''") + "'"}`,
    // Verweise zuerst: Listen wie contains=.*String erfassen nur schon bekannte Gruppen
    ...Object.entries(data.gruppen).filter(([, to]) => to).map(([from, to]) => `silent! highlight! link ${from} ${to}`),
    ...stack[0],
  ].join('\n') + '\n';
}

async function replay(file, data) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'vim-replay-'));
  try {
    const rules = path.join(dir, 'rules.vim');
    const output = path.join(dir, 'tokens');
    fs.writeFileSync(rules, script(data, dir));
    await runVim(VIM, 'syntax-replay.vim', { VH_IN: file, VH_OUT: output, VH_RULES: slash(rules) });
    return fs.readFileSync(output, 'utf8').split(/\r?\n/).filter(Boolean).map((row) => {
      const [line, start, length, group] = row.split('\t');
      return { line: +line, start: +start, length: +length, type: tokenType(group) };
    });
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

// Gruppe je Zeichen, damit der Anteil richtiger Zeichen zaehlbar ist
const perChar = (tokens) => {
  const map = new Map();
  for (const t of tokens) {
    for (let i = 0; i < t.length; i++) map.set(`${t.line}:${t.start + i}`, t.type);
  }
  return map;
};

async function main() {
  const dir = path.join(ROOT, 'syntaxdaten');
  let same = 0;
  let total = 0;
  let wrongChars = 0;
  let allChars = 0;
  for (const name of fs.readdirSync(dir).filter((f) => f.endsWith('.json')).sort()) {
    const data = JSON.parse(fs.readFileSync(path.join(dir, name), 'utf8'));
    if (!data.befehle) throw new Error(`${name}: keine Befehle (mit normalem Vim erzeugt)`);
    for (const test of data.testdateien) {
      const file = path.join(ROOT, 'test', test);
      const text = fs.readFileSync(file, 'utf8');
      const want = perChar(await highlight({
        vimPath: VIM, text, fileName: file, filetype: '', scheme: 'default', background: 'light',
      }));
      const got = perChar(await replay(file, data));
      const keys = new Set([...want.keys(), ...got.keys()]);
      const wrong = [...keys].filter((k) => want.get(k) !== got.get(k));
      total++;
      allChars += keys.size;
      wrongChars += wrong.length;
      if (!wrong.length) same++;
      else console.log(`${test}: ${wrong.length} von ${keys.size} Zeichen anders, z. B. Zeile ${+wrong[0].split(':')[0] + 1}: ` +
        `${want.get(wrong[0])} statt ${got.get(wrong[0])}`);
    }
  }
  console.log(`\n${same} von ${total} Testdateien gleich; ${wrongChars} von ${allChars} gefaerbten Zeichen anders`);
}

main().catch((error) => { console.error(error.message); process.exit(1); });
