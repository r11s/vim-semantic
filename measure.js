'use strict';
// Misst fuer ein Theme, wie genau die Erweiterung die Darstellung von Vim trifft.
//   node measure.js <schema> [light|dark]      z. B.  node measure.js blue
// Soll: vim/reference.vim. Ist: Tokens der Erweiterung + Theme-Datei.
// Rechnerisch; was VS Code tatsaechlich anzeigt, wird nicht geprueft.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { runVim, highlight, tokenType } = require('./vim');

const TESTDIR = process.env.TESTDIR || path.join(__dirname, 'test');
const VIM = process.env.VIM_PATH || 'vim';

const readJson = (file) => JSON.parse(fs.readFileSync(path.join(__dirname, file), 'utf8'));
const percent = (part, total) => (total ? (Math.floor((part / total) * 1000) / 10).toFixed(1) : '-');

function findTheme(scheme, background) {
  const { themes, types } = readJson('scheme.json');
  const matches = Object.entries(themes)
    .filter(([, t]) => t.scheme === scheme && (!background || t.background === background));
  if (matches.length !== 1) {
    const list = Object.keys(themes).join(', ');
    throw new Error(matches.length
      ? `"${scheme}" gibt es hell und dunkel: bitte light oder dark angeben.`
      : `Kein Theme "${scheme || ''}". Vorhanden: ${list}`);
  }
  const [label, settings] = matches[0];
  const { contributes } = readJson('package.json');
  const entry = contributes.themes.find((t) => t.label === label);
  const groups = contributes.configuration.properties['vimHighlight.backgroundGroups']?.default || [];
  return {
    label, ...settings, types: new Set(types), theme: readJson(entry.path),
    marked: new Set(groups.map(tokenType)), groups,
  };
}

async function reference(file, text, current) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'vim-measure-'));
  try {
    const input = path.join(dir, path.basename(file));
    const output = path.join(dir, '.reference');
    fs.writeFileSync(input, text, 'utf8');
    await runVim(VIM, 'reference.vim', {
      VH_IN: input, VH_OUT: output, VH_SCHEME: current.scheme, VH_BACKGROUND: current.background,
    });
    return fs.readFileSync(output, 'utf8').split(/\r?\n/).filter((row) => row && !row.startsWith('#'))
      .map((row) => {
        const [line, start, length, group, fg, bg, style = ''] = row.split('\t');
        return { line: +line, start: +start, length: +length, group, fg, bg, style };
      });
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

// Aussehen je Position, so wie die Erweiterung es VS Code vorgibt
async function actual(file, text, current) {
  const { theme, types } = current;
  const plain = {
    token: '-',
    fg: theme.colors['editor.foreground'].toLowerCase(),
    bg: theme.colors['editor.background'].toLowerCase(),
    style: '',
  };
  const tokens = await highlight({
    vimPath: VIM, text, fileName: file, filetype: '',
    scheme: current.scheme, background: current.background,
  });
  const at = new Map();
  for (const t of tokens) {
    if (!types.has(t.type)) continue;
    const rule = theme.semanticTokenColors[t.type] || {};
    const look = {
      token: t.type.slice(4),
      fg: (rule.foreground || plain.fg).toLowerCase(),
      // Hintergrund nur fuer die Gruppen, die die Erweiterung hinterlegt
      bg: ((current.marked.has(t.type) && current.backgrounds?.[t.type]) || plain.bg).toLowerCase(),
      style: (rule.bold ? 'b' : '') + (rule.italic ? 'i' : '') +
        (rule.underline ? 'u' : '') + (rule.strikethrough ? 's' : ''),
    };
    for (let i = t.start; i < t.start + t.length; i++) at.set(`${t.line}:${i}`, look);
  }
  const look = (line, column) => at.get(`${line}:${column}`) || plain;
  look.normal = plain.bg;
  return look;
}

async function measure(file, current) {
  const text = fs.readFileSync(path.join(TESTDIR, file), 'utf8');
  const lines = text.split(/\r?\n/);
  const wanted = await reference(file, text, current);
  const got = await actual(path.join(TESTDIR, file), text, current);
  const result = { file, total: 0, fg: 0, style: 0, bg: 0, all: 0, space: 0, spaceOk: 0, errors: [] };
  let open = null;
  for (const want of wanted) {
    const chars = lines[want.line].slice(want.start, want.start + want.length);
    const is = got(want.line, want.start);
    if (!chars.trim()) {
      // Eigene Spalte: nur Leerraum, der in Soll oder Ist hinterlegt ist
      if (want.bg !== got.normal || is.bg !== got.normal) {
        result.space += want.length;
        if (want.bg === is.bg) result.spaceOk += want.length;
      }
      open = null;
      continue; // zaehlt in den uebrigen Spalten nicht
    }
    const ok = { fg: is.fg === want.fg, style: is.style === want.style, bg: is.bg === want.bg };
    result.total += want.length;
    for (const key of ['fg', 'style', 'bg']) if (ok[key]) result[key] += want.length;
    if (ok.fg && ok.style && ok.bg) { result.all += want.length; open = null; continue; }
    const describe = (x) => `${x.fg} auf ${x.bg}${x.style ? ` [${x.style}]` : ''}`;
    const detail = `Soll ${want.group} ${describe(want)} | Ist ${is.token} ${describe(is)}`;
    // Nebeneinanderliegende gleiche Abweichungen zusammenfassen
    if (open && open.line === want.line && open.end === want.start && open.detail === detail) {
      open.text += chars;
      open.end += want.length;
    } else {
      open = { line: want.line, end: want.start + want.length, text: chars, detail };
      result.errors.push(open);
    }
  }
  return result;
}

async function main() {
  const current = findTheme(process.argv[2], process.argv[3]);
  const files = fs.readdirSync(TESTDIR)
    .filter((f) => /^\d{2,3}_/.test(f) && !/\.(exe|o|swp)$/.test(f)).sort();
  if (!files.length) throw new Error(`Keine Testdateien in ${TESTDIR}`);

  const report = [`${current.label}, Anteil richtiger Zeichen in % (ohne Leerraum)`,
    `Hinterlegte Gruppen: ${current.groups.join(', ') || 'keine'}. ` +
    'Hg.Leer: hinterlegter Leerraum (- = keiner vorhanden)', ''];
  console.log(report[1]);
  const row = (name, r) => name.padEnd(22) + String(r.total).padStart(7) +
    ['fg', 'style', 'bg', 'all'].map((k) => percent(r[k], r.total).padStart(9)).join('') +
    percent(r.spaceOk, r.space).padStart(9);
  const print = (line) => { console.log(line); report.push(line); };
  print('Datei'.padEnd(22) + 'Zeichen'.padStart(7) +
    ['Farbe', 'Stil', 'Hintergr', 'alles', 'Hg.Leer'].map((h) => h.padStart(9)).join(''));

  const sum = { total: 0, fg: 0, style: 0, bg: 0, all: 0, space: 0, spaceOk: 0 };
  const details = [];
  for (const file of files) {
    const result = await measure(file, current);
    for (const key of Object.keys(sum)) sum[key] += result[key];
    print(row(file, result));
    if (result.errors.length) {
      details.push('', `== ${file}`, ...result.errors.map(
        (e) => `Zeile ${e.line + 1}: ${JSON.stringify(e.text)}  ${e.detail}`));
    }
  }
  print(row('gesamt', sum));

  const dir = path.join(__dirname, 'messung');
  fs.mkdirSync(dir, { recursive: true });
  const name = `${current.scheme}-${current.background}.txt`;
  fs.writeFileSync(path.join(dir, name), [...report, '', 'Abweichungen', ...details].join('\n') + '\n');
  console.log(`\nAbweichungen im Einzelnen: messung/${name}`);
}

main().catch((error) => { console.error(error.message); process.exit(1); });
