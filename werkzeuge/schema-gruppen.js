'use strict';
// Haelt fest, wo ein Farbschema eine Gruppe anders zuordnet als in syntaxdaten/<typ>.json.
// Ergebnis: schemata/<typ>.json (nur die Abweichungen, je Schema).
//   VIM_PATH=... node werkzeuge/schema-gruppen.js c
const fs = require('fs');
const os = require('os');
const path = require('path');
const { runVim } = require('../vim');

const root = path.join(__dirname, '..');

async function main() {
  const [type] = process.argv.slice(2);
  if (!type) throw new Error('Aufruf: node werkzeuge/schema-gruppen.js <typ>');
  const data = JSON.parse(fs.readFileSync(path.join(root, 'syntaxdaten', `${type}.json`), 'utf8'));
  const { themes } = JSON.parse(fs.readFileSync(path.join(root, 'scheme.json'), 'utf8'));
  const schemes = [...new Set(Object.values(themes).map((t) => `${t.scheme} ${t.background}`))].sort();

  // Zuordnung nach syntaxdaten: den Verweisen bis zum Ende folgen
  const links = new Map(Object.entries(data.gruppen).map(([name, to]) => [name.toLowerCase(), to]));
  const normal = (group) => {
    let name = group;
    for (let n = 0; n < 20; n++) {
      const to = links.get(name.toLowerCase());
      if (!to || to.toLowerCase() === name.toLowerCase()) break;
      name = to;
    }
    return name;
  };

  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'vimsem-'));
  try {
    const answer = path.join(dir, 'out');
    await runVim(process.env.VIM_PATH || 'vim', 'scheme-groups.vim', {
      VH_GROUPS: Object.keys(data.gruppen).join(','), VH_SCHEMES: schemes.join(','),
      VH_OUT: answer, VH_FILETYPE: type,
    });
    const found = JSON.parse(fs.readFileSync(answer, 'utf8'));
    const result = {};
    for (const scheme of schemes) {
      const different = Object.entries(found[scheme])
        .filter(([group, to]) => to && to.toLowerCase() !== normal(group).toLowerCase())
        .sort(([a], [b]) => a.localeCompare(b, 'en'));
      if (different.length) result[scheme] = Object.fromEntries(different);
    }
    const out = path.join(root, 'schemata', `${type}.json`);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, `${JSON.stringify(result, null, 1)}\n`);
    console.log(`${out}: ${schemes.length} Schemata, ${Object.keys(result).length} mit Abweichungen`);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

main().catch((error) => { console.error(error.stack); process.exit(1); });
