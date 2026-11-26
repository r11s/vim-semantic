'use strict';
// Fuegt ein Vim-Colorscheme als VS-Code-Theme hinzu (oder erneuert es).
// Bereits erzeugte Themes im Ordner themes bleiben erhalten.
//   node generate.js [colorscheme] [light|dark]
const fs = require('fs');
const os = require('os');
const path = require('path');
const { runVim, tokenType } = require('./vim');

const FILETYPES = ['python', 'javascript', 'typescript', 'sh', 'json', 'c', 'cpp',
  'vim', 'html', 'css', 'markdown', 'yaml', 'java', 'go', 'rust', 'sql', 'cs', 'php', 'r', 'ps1',
  'swift', 'kotlin', 'ruby', 'asm', 'dart', 'objc', 'vb', 'lua', 'ada', 'fortran', 'scala', 'perl',
  'matlab', 'pascal', 'julia',
  'nix', 'dosbatch', 'groovy', 'haskell', 'lisp', 'gdscript', 'zig', 'ocaml', 'cobol', 'prolog',
  'solidity', 'clojure', 'glsl', 'erlang', 'tcl', 'cuda', 'd', 'sas', 'pyrex', 'awk', 'verilog',
  'systemverilog', 'vhdl', 'abap', 'scheme', 'raku', 'sml', 'st', 'uc', 'stata', 'forth',
  'scilab', 'autohotkey', 'arduino', 'nu', 'racket', 'mojo', 'progress', 'elm', 'basic'];

async function main() {
  const scheme = process.argv[2] || 'default';
  const background = process.argv[3] || 'light';
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'vim-theme-'));
  const output = path.join(dir, 'theme.json');
  await runVim(process.env.VIM_PATH || 'vim', 'export-theme.vim', {
    VH_OUT: output, VH_SCHEME: scheme, VH_BACKGROUND: background,
    VH_FILETYPES: FILETYPES.join(','),
  });
  const data = JSON.parse(fs.readFileSync(output, 'utf8'));
  fs.rmSync(dir, { recursive: true, force: true });

  const colors = {};
  const backgrounds = {};
  for (const [group, hl] of Object.entries(data.groups).sort()) {
    const id = tokenType(group);
    const has = (name) => hl.attributes.includes(name);
    const reverse = has('reverse') || has('inverse');
    const foreground = hl.foreground || data.foreground;
    const background = hl.background || data.background;
    // Semantic Tokens kennen keinen Hintergrund; die Erweiterung setzt ihn als Decoration
    const shownBackground = reverse ? foreground : background;
    if (shownBackground.toLowerCase() !== data.background.toLowerCase()) backgrounds[id] = shownBackground;
    colors[id] = {
      foreground: reverse ? background : foreground,
      bold: has('bold'),
      italic: has('italic'),
      underline: has('underline') || has('undercurl'),
      strikethrough: has('strikethrough'),
    };
  }

  const type = data.type;
  const write = (file, value) =>
    fs.writeFileSync(path.join(__dirname, file), JSON.stringify(value, null, 2) + '\n');

  const themeDir = path.join(__dirname, 'themes');
  fs.mkdirSync(themeDir, { recursive: true });
  const readThemes = () => fs.readdirSync(themeDir).filter((f) => f.endsWith('.json')).sort()
    .map((file) => ({ file, theme: JSON.parse(fs.readFileSync(path.join(themeDir, file), 'utf8')) }));

  // Gibt es das Theme schon, wird seine Datei ersetzt
  const existing = readThemes()
    .find((entry) => entry.theme.vimScheme === scheme && entry.theme.type === type);
  const target = existing ? existing.file : `vim-${scheme}-${type}-color-theme.json`;
  write(`themes/${target}`, {
    name: '', // wird unten vergeben
    type,
    semanticHighlighting: true,
    colors: { 'editor.background': data.background, 'editor.foreground': data.foreground },
    tokenColors: [],
    semanticTokenColors: colors,
    vimBackgrounds: backgrounds, // eigene Schluessel, VS Code wertet sie nicht aus
    vimScheme: scheme,
  });

  // Alles Weitere ergibt sich aus den vorhandenen Theme-Dateien
  const themes = [];
  const schemes = {};
  const ids = new Set();
  const entries = readThemes().filter((entry) => entry.theme.vimScheme);
  // Name "VimSem <schema>", mit light/dark nur, wenn es von dem Schema beides gibt
  const label = ({ theme }) => {
    const both = entries.filter((e) => e.theme.vimScheme === theme.vimScheme).length > 1;
    return `VimSem ${theme.vimScheme}${both ? ` ${theme.type}` : ''}`;
  };
  let generated;
  for (const entry of entries) {
    const { file, theme } = entry;
    const name = label(entry);
    if (file === target) generated = name;
    if (theme.name !== name) {
      theme.name = name;
      write(`themes/${file}`, theme);
    }
    themes.push({ label: name, uiTheme: theme.type === 'dark' ? 'vs-dark' : 'vs', path: `./themes/${file}` });
    schemes[name] = { scheme: theme.vimScheme, background: theme.type, backgrounds: theme.vimBackgrounds || {} };
    Object.keys(theme.semanticTokenColors).forEach((id) => ids.add(id));
  }
  const types = [...ids].sort().map((id) => ({ id, description: `Vim: ${id.slice(4)}` }));

  write('scheme.json', { themes: schemes, types: types.map((t) => t.id) });
  write('package.json', {
    name: 'vim-highlight',
    displayName: 'Vim Highlight (Prototyp)',
    publisher: 'local',
    version: '0.0.1',
    engines: { vscode: '^1.80.0' },
    main: './extension.js',
    activationEvents: ['onStartupFinished'],
    capabilities: {
      untrustedWorkspaces: { supported: 'limited', restrictedConfigurations: ['vimHighlight.vimPath'] },
    },
    contributes: {
      themes,
      semanticTokenTypes: types,
      configuration: {
        title: 'Vim Highlight',
        properties: {
          'vimHighlight.vimPath': { type: 'string', default: 'vim', scope: 'machine-overridable', description: 'Pfad zu Vim' },
          'vimHighlight.maxLines': { type: 'number', default: 3000, description: 'Groessere Dateien bleiben ungefaerbt' },
          'vimHighlight.backgroundGroups': {
            type: 'array', items: { type: 'string' }, default: ['Todo', 'Error', 'Constant'],
            description: 'Vim-Gruppen, deren Hintergrundfarbe angezeigt wird',
          },
        },
      },
    },
  });
  console.log(`${generated}: ${Object.keys(colors).length} Gruppen`);
  console.log(`Verfuegbare Themes: ${themes.map((t) => t.label).join(', ')}`);
}

main().catch((error) => { console.error(error.message); process.exit(1); });
