// Erzeugt dateitypen.json: welcher Dateiname gehoert zu welchem Satz Syntaxregeln?
// Die Kandidaten stammen aus Vims eigenen Tabellen, die Antwort gibt Vim selbst (an einer
// leeren Datei dieses Namens). Wo Vim nach dem Inhalt entscheidet, steht das in erkennen.js.
//
//   VIM_PATH=... VIMRUNTIME=... node werkzeuge/dateitypen.js
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.join(__dirname, '..');
const runtime = process.env.VIMRUNTIME;
const vim = process.env.VIM_PATH || 'vim';
if (!runtime) throw new Error('VIMRUNTIME fehlt');
const types = new Set(fs.readdirSync(path.join(root, 'syntaxdaten'))
  .filter((f) => /^[a-z0-9]+\.json$/.test(f)).map((f) => f.slice(0, -5)));

const read = (file) => fs.readFileSync(path.join(runtime, file), 'utf8').replace(/\r/g, '');
const table = (source, name) => {
  const block = source.slice(source.indexOf(`const ${name} = {`));
  return [...block.slice(0, block.indexOf('\n}')).matchAll(/^\s*"([^"]+)":/gm)].map((m) => m[1]);
};

// "*.[sS]" und "x{a,b}" ausschreiben
const expand = (pattern) => {
  const set = /\[([^\]\^-]+)\]/.exec(pattern);
  const choice = /\{([^{}]*)\}/.exec(pattern);
  const found = set || choice;
  if (!found) return [pattern];
  const parts = set ? [...set[1]] : choice[1].split(',');
  return parts.flatMap((part) => expand(pattern.slice(0, found.index) + part + pattern.slice(found.index + found[0].length)));
};

const extensions = new Set();
const names = new Set();
const ft = read('autoload/dist/ft.vim');
for (const extension of table(ft, 'ft_from_ext')) extensions.add(extension);
for (const name of table(ft, 'ft_from_name')) names.add(name);
for (const line of read('filetype.vim').replace(/\n\s*\\/g, '').split('\n')) {
  const found = /^\s*au(?:tocmd)?!?\s+(?:filetypedetect\s+)?BufNewFile,BufRead\s+(\S+)\s/.exec(line);
  if (!found) continue;
  for (const pattern of found[1].split(/,(?![^{]*\})/).flatMap(expand)) {
    if (/^\*\.[^*?[\]{}/\\]+$/.test(pattern)) extensions.add(pattern.slice(2));
    else if (!/[*?[\]{}/\\]/.test(pattern)) names.add(pattern);
  }
}

const work = fs.mkdtempSync(path.join(os.tmpdir(), 'dateitypen-'));
const candidates = [
  ...[...extensions].map((key) => ({ key, kind: 'endungen', file: `x.${key}` })),
  ...[...names].map((key) => ({ key, kind: 'namen', file: key })),
].filter((c) => !c.file.includes('/') && c.file !== '.' && c.file !== '..');
const script = `
let &runtimepath = $VIMRUNTIME
set nomodeline noswapfile nofileignorecase
filetype on
let out = []
for f in readfile($VH_LIST)
  silent! execute 'edit ' . fnameescape(f)
  call add(out, &filetype . "\\t" . f)
  silent! bwipeout!
endfor
call writefile(out, $VH_OUT)
qall!
`;
const list = path.join(work, 'liste');
const out = path.join(work, 'antwort');
fs.writeFileSync(path.join(work, 'frage.vim'), script);
fs.writeFileSync(list, candidates.map((c) => path.join(work, 'leer', c.file)).join('\n') + '\n');
execFileSync(vim, ['-es', '-N', '-u', 'NONE', '-i', 'NONE', '-S', path.join(work, 'frage.vim')],
  { env: { ...process.env, VH_LIST: list, VH_OUT: out }, timeout: 120000 });
const answers = fs.readFileSync(out, 'utf8').split('\n').filter(Boolean).map((l) => l.split('\t')[0]);
fs.rmSync(work, { recursive: true, force: true });
if (answers.length !== candidates.length) throw new Error(`${answers.length} Antworten auf ${candidates.length} Fragen`);

const result = { endungen: {}, namen: {} };
// "fremd": Namen und Endungen, fuer die Vim einen Typ ohne Regeln waehlt. Fuer sie gelten
// die Muster nach Namensanfang ("Makefile.am") nicht.
const foreign = { endungen: [], namen: [] };
candidates.forEach((c, i) => {
  if (types.has(answers[i])) result[c.kind][c.key] = answers[i];
  // "*.txt" und "*.conf" greifen in Vim erst nach den Mustern nach Namensanfang
  else if (answers[i] && !(c.kind === 'endungen' && ['txt', 'conf'].includes(c.key))) foreign[c.kind].push(c.key);
});
const sorted = (object) => Object.fromEntries(Object.entries(object).sort(([a], [b]) => (a < b ? -1 : 1)));
fs.writeFileSync(path.join(root, 'dateitypen.json'),
  JSON.stringify({ endungen: sorted(result.endungen), namen: sorted(result.namen),
    fremd: { endungen: foreign.endungen.sort(), namen: foreign.namen.sort() } }, null, 1) + '\n');
console.log(`${Object.keys(result.endungen).length} Endungen, ${Object.keys(result.namen).length} Namen`);
const missing = [...types].filter((type) => !Object.values(result.endungen).includes(type));
console.log('Typen ohne Endung:', missing.join(' ') || 'keine');
