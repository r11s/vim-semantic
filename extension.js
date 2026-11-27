'use strict';
const fs = require('fs');
const path = require('path');
const vscode = require('vscode');
const { highlighter, loadData, tokenType } = require('./faerben');
const { typeFor } = require('./erkennen');
const { endungen, namen } = require('./dateitypen.json');
const { themes, types } = require('./scheme.json');

// VS-Code-Sprachen -> Syntaxregeln. Die Zuordnung zaehlt bei ungespeicherten Dateien; bei
// gespeicherten entscheiden wie in Vim Dateiname und Inhalt (erkennen.js).
const LANGUAGES = {
  abap: 'abap', abl: 'progress', ada: 'ada', ahk: 'autohotkey', asm: 'asm', awk: 'awk', basic: 'basic',
  bat: 'dosbatch', c: 'c',
  clojure: 'clojure', cobol: 'cobol', cpp: 'cpp', csharp: 'cs', css: 'css', 'cuda-cpp': 'cuda',
  cython: 'pyrex', d: 'd', dart: 'dart', elm: 'elm', erlang: 'erlang', forth: 'forth',
  gdscript: 'gdscript', glsl: 'glsl', go: 'go', groovy: 'groovy', haskell: 'haskell',
  html: 'html', java: 'java', javascript: 'javascript', json: 'json', julia: 'julia',
  kotlin: 'kotlin', lisp: 'lisp', lua: 'lua', markdown: 'markdown', matlab: 'matlab',
  mojo: 'mojo', nix: 'nix', nushell: 'nu', 'objective-c': 'objc', ocaml: 'ocaml',
  pascal: 'pascal', perl: 'perl', php: 'php', plsql: 'sql', powershell: 'ps1',
  processing: 'arduino', progress: 'progress', prolog: 'prolog', python: 'python', r: 'r', racket: 'racket', raku: 'raku', ruby: 'ruby',
  rust: 'rust', sas: 'sas', scala: 'scala', scheme: 'scheme', scilab: 'scilab',
  shellscript: 'sh', smalltalk: 'st', solidity: 'solidity', sql: 'sql', standardml: 'sml',
  stata: 'stata', swift: 'swift', systemverilog: 'systemverilog', tcl: 'tcl',
  typescript: 'typescript', unrealscript: 'uc', vb: 'vb', verilog: 'verilog', vhdl: 'vhdl',
  yaml: 'yaml', zig: 'zig',
  diff: 'diff', dockerfile: 'dockerfile', ini: 'dosini', javascriptreact: 'javascriptreact',
  jsonc: 'jsonc', less: 'less', makefile: 'make', scss: 'scss', toml: 'toml',
  typescriptreact: 'typescriptreact', xml: 'xml',
};
// Typen mit mehreren Regelsaetzen: unter diesem Namen entscheidet bei ungespeicherten
// Dateien wie sonst der Inhalt
const UNTITLED = { sh: 'Untitled.sh', make: 'Untitled.mk', diff: 'Untitled.diff' };
// Endungen und Namen, bei denen VS Code die Erweiterung auch ohne passende Sprache fragt.
// Die zweite Liste sind Endungen, ueber die nur der Inhalt entscheidet.
const EXTENSIONS = [...new Set([...Object.keys(endungen),
  'h', 'm', 'pl', 'v', 'p', 'i', 'd', 'r', 'cls', 'sh', 'cmd', 'inc', 'pp', 'lpr', 'sc', 'class'])];
const NAMES = Object.keys(namen);

const engines = new Map(); // Dateityp -> Faerber, beim ersten Gebrauch geladen
const engineFor = (type) => {
  if (!engines.has(type)) engines.set(type, highlighter(loadData(type)));
  return engines.get(type);
};

function activate(context) {
  const legend = new vscode.SemanticTokensLegend(types);
  const index = new Map(types.map((type, i) => [type, i]));
  const log = vscode.window.createOutputChannel('VimSem');

  // Protokoll zur Fehlersuche: immer im Ausgabekanal, auf Wunsch (vimsem.logFile)
  // auch in protokoll.txt im Erweiterungsordner
  const logFile = path.join(__dirname, 'protokoll.txt');
  const note = (message) => {
    log.appendLine(message);
    if (!vscode.workspace.getConfiguration('vimsem').get('logFile')) return;
    try {
      // Ab 1 MB neu beginnen, damit die Datei nicht unbegrenzt waechst
      const full = fs.existsSync(logFile) && fs.statSync(logFile).size > 1024 * 1024;
      const write = full ? fs.writeFileSync : fs.appendFileSync;
      write(logFile, `${new Date().toISOString()} ${message}\n`);
    } catch {
      // Das Protokoll darf die Faerbung nie stoeren
    }
  };
  const semantic = vscode.workspace.getConfiguration('editor').get('semanticHighlighting.enabled');
  note(`Aktiviert. Farbschema: ${vscode.workspace.getConfiguration('workbench').get('colorTheme')}, ` +
    `semanticHighlighting: ${semantic}`);
  const showDocument = (document) => {
    if (document.uri.scheme === 'file' || document.uri.scheme === 'untitled') {
      note(`Offen: ${path.basename(document.fileName)} (Sprache ${document.languageId})`);
    }
  };
  vscode.workspace.textDocuments.forEach(showDocument);
  context.subscriptions.push(vscode.workspace.onDidOpenTextDocument(showDocument));

  // Zum aktiven VS-Code-Theme gehoert genau ein Vim-Colorscheme
  const activeTheme = () => vscode.workspace.getConfiguration('workbench').get('colorTheme');

  // Hintergruende: Semantic Tokens kennen keine, deshalb Decorations
  const decorations = new Map(); // Farbe -> DecorationType
  const cache = new Map(); // Dokument -> { version, theme, ranges: Farbe -> Range[] }

  const decorationFor = (color) => {
    if (!decorations.has(color)) {
      const type = vscode.window.createTextEditorDecorationType({
        backgroundColor: color,
        rangeBehavior: vscode.DecorationRangeBehavior.ClosedClosed,
      });
      context.subscriptions.push(type);
      decorations.set(color, type);
    }
    return decorations.get(color);
  };
  // Setzt alle Farben; ohne passenden Eintrag werden sie damit entfernt
  const decorate = (editor) => {
    const entry = cache.get(editor.document.uri.toString());
    const valid = entry && entry.theme === activeTheme() && entry.version === editor.document.version;
    for (const [color, type] of decorations) {
      editor.setDecorations(type, (valid && entry.ranges.get(color)) || []);
    }
  };
  const decorateDocument = (document) => vscode.window.visibleTextEditors
    .filter((editor) => editor.document === document).forEach(decorate);
  const forget = (document) => {
    cache.delete(document.uri.toString());
    decorateDocument(document);
  };
  const remember = (document, version, theme, tokens) => {
    const groups = vscode.workspace.getConfiguration('vimsem', document.uri).get('backgroundGroups') || [];
    const wanted = new Set(groups.map(tokenType));
    const ranges = new Map();
    let count = 0;
    for (const t of tokens) {
      const color = wanted.has(t.type) && themes[theme].backgrounds?.[t.type];
      if (!color) continue;
      decorationFor(color);
      if (!ranges.has(color)) ranges.set(color, []);
      ranges.get(color).push(new vscode.Range(t.line, t.start, t.line, t.start + t.length));
      count++;
    }
    cache.set(document.uri.toString(), { version, theme, ranges });
    decorateDocument(document);
    return count;
  };

  // Nach einem Themewechsel muss VS Code die Tokens neu anfordern
  const changed = new vscode.EventEmitter();
  context.subscriptions.push(changed, vscode.workspace.onDidChangeConfiguration((event) => {
    const theme = event.affectsConfiguration('workbench.colorTheme');
    const settings = event.affectsConfiguration('vimsem.backgroundGroups');
    if (theme || settings) {
      if (theme) note(`Farbschema: ${activeTheme()}`);
      cache.clear();
      vscode.window.visibleTextEditors.forEach(decorate);
      changed.fire();
    }
  }), vscode.window.onDidChangeVisibleTextEditors((editors) => editors.forEach(decorate)),
  vscode.workspace.onDidCloseTextDocument((document) => cache.delete(document.uri.toString())));

  const provider = {
    onDidChangeSemanticTokens: changed.event,
    provideDocumentSemanticTokens(document, cancel) {
      const theme = activeTheme();
      const current = themes[theme];
      if (!current) {
        forget(document);
        return null;
      }

      const name = path.basename(document.fileName);
      note(`Anfrage: ${name} (${document.languageId}, ${document.lineCount} Zeilen)`);
      const version = document.version;
      try {
        const text = document.getText();
        let type = typeFor(document.fileName, text);
        if (!type && document.isUntitled) {
          type = LANGUAGES[document.languageId] || null;
          if (UNTITLED[type]) type = typeFor(UNTITLED[type], text);
        }
        if (!type) {
          forget(document);
          note(`${name}: keine Syntaxregeln fuer diese Datei`);
          return null;
        }
        const start = Date.now();
        const tokens = engineFor(type).highlight(text, { scheme: current.scheme, background: current.background });
        const time = Date.now() - start;
        const builder = new vscode.SemanticTokensBuilder(legend);
        for (const t of tokens) {
          if (index.has(t.type)) builder.push(t.line, t.start, t.length, index.get(t.type), 0);
        }
        // Ergebnisse zu einem inzwischen geaenderten Text wuerden verrutschen
        const upToDate = !cancel.isCancellationRequested && document.version === version && theme === activeTheme();
        const marked = upToDate ? remember(document, version, theme, tokens) : 0;
        note(`${name}: ${tokens.length} Abschnitte (${type}) in ${time} ms, ` +
          `${tokens.filter((t) => index.has(t.type)).length} davon mit bekannter Gruppe, ${marked} Hintergruende`);
        return builder.build();
      } catch (error) {
        note(String(error.stack || error));
        vscode.window.showWarningMessage('VimSem: Faerben fehlgeschlagen (siehe Ausgabe "VimSem").');
        return null;
      }
    },
  };

  const selector = [
    // "plaintext": Skripte ohne Endung ("#!...") und Sicherungskopien wie "x.py.bak"
    ...[...Object.keys(LANGUAGES), 'plaintext'].flatMap((language) => [
      { scheme: 'file', language },
      { scheme: 'untitled', language },
    ]),
    { scheme: 'file', pattern: `**/*.{${EXTENSIONS.join(',')}}` },
    { scheme: 'file', pattern: `**/{${NAMES.join(',')}}` },
  ];
  context.subscriptions.push(
    log,
    vscode.languages.registerDocumentSemanticTokensProvider(selector, provider, legend)
  );
}

module.exports = { activate };
