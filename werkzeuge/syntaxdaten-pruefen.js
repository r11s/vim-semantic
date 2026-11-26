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
      // Mit "$" am Anfang liest Vim die Datei direkt. Einen Pfad wie "C:/..." haelt das
      // Vim aus Git for Windows nicht fuer vollstaendig und sucht ihn vergeblich.
      stack.at(-1).push(`syntax include ${cluster}$VH_DIR/${path.basename(file)}`);
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
    await runVim(VIM, 'syntax-replay.vim', {
      VH_IN: file, VH_OUT: output, VH_RULES: slash(rules), VH_DIR: slash(dir),
    });
    const message = fs.existsSync(`${output}.err`) ? fs.readFileSync(`${output}.err`, 'utf8').trim() : '';
    const tokens = fs.readFileSync(output, 'utf8').split(/\r?\n/).filter(Boolean).map((row) => {
      const [line, start, length, group] = row.split('\t');
      return { line: +line, start: +start, length: +length, type: tokenType(group) };
    });
    return { tokens, message };
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
      const result = await replay(file, data);
      const got = perChar(result.tokens);
      const keys = new Set([...want.keys(), ...got.keys()]);
      const wrong = [...keys].filter((k) => want.get(k) !== got.get(k));
      total++;
      allChars += keys.size;
      wrongChars += wrong.length;
      if (!wrong.length) same++;
      else {
        console.log(`${test}: ${wrong.length} von ${keys.size} Zeichen anders, z. B. Zeile ${+wrong[0].split(':')[0] + 1}: ` +
          `Vim ${want.get(wrong[0]) ?? 'ohne Gruppe'}, aus den Daten ${got.get(wrong[0]) ?? 'ohne Gruppe'}`);
        if (result.message) console.log(`  Letzte Meldung von Vim: ${result.message}`);
      }
    }
  }
  console.log(`\n${same} von ${total} Testdateien gleich; ${wrongChars} von ${allChars} gefaerbten Zeichen anders`);
}

main().catch((error) => { console.error(error.message); process.exit(1); });
