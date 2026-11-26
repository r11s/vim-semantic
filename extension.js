'use strict';
const fs = require('fs');
const path = require('path');
const vscode = require('vscode');
const { highlight, tokenType } = require('./vim');
const { themes, types } = require('./scheme.json');

// VS-Code-Sprachen, fuer die ein Vim-Syntax vorgesehen ist
const LANGUAGES = ['python', 'javascript', 'typescript', 'shellscript', 'json', 'jsonc', 'c', 'cpp',
  'vim', 'viml', 'html', 'css', 'markdown', 'yaml', 'java', 'go', 'rust', 'sql', 'csharp', 'php',
  'r', 'powershell', 'swift', 'kotlin', 'ruby', 'asm', 'dart', 'objective-c', 'vb', 'lua', 'ada',
  'fortran', 'scala', 'perl', 'matlab', 'pascal', 'julia',
  // weitere Sprachen der Rangliste (siehe SPRACHEN.md); unbekannte Kennungen schaden nicht
  'nix', 'bat', 'groovy', 'haskell', 'lisp', 'gdscript', 'zig', 'ocaml', 'cobol', 'prolog',
  'solidity', 'plsql', 'clojure', 'glsl', 'erlang', 'tcl', 'cuda-cpp', 'd', 'sas', 'cython',
  'awk', 'verilog', 'systemverilog', 'vhdl', 'abap', 'scheme', 'raku', 'standardml', 'smalltalk',
  'unrealscript', 'stata', 'forth', 'scilab', 'ahk', 'processing', 'nushell', 'racket', 'mojo',
  'elm'];
// Ohne passende Spracherweiterung kennt VS Code den Typ nicht; dann zaehlt die Endung
const EXTENSIONS = ['asm', 'swift', 'kt', 'dart', 'adb', 'ads', 'f90', 'scala', 'm', 'pas', 'jl',
  'R', 'r', 'vb',
  'nix', 'bat', 'cmd', 'groovy', 'hs', 'lisp', 'gd', 'zig', 'ml', 'cob', 'pl', 'sol', 'sql', 'clj',
  'glsl', 'erl', 'tcl', 'cu', 'd', 'vim', 'sas', 'pyx', 'el', 'awk', 'v', 'vhd', 'vbs', 'abap',
  'scm', 'raku', 'sv', 'sml', 'st', 'uc', 'do', 'fth', 'sce', 'ahk', 'pde', 'nu', 'rkt', 'mojo',
  'bas', 'p', 'elm'];
// Nur noetig, wenn Vim den Typ nicht am Dateinamen erkennt (etwa bei "Untitled")
const FILETYPES = { shellscript: 'sh', viml: 'vim', csharp: 'cs', powershell: 'ps1',
  'objective-c': 'objc', plaintext: '', bat: 'dosbatch', 'cuda-cpp': 'cuda', cython: 'pyrex',
  standardml: 'sml', smalltalk: 'st', unrealscript: 'uc', ahk: 'autohotkey',
  processing: 'arduino', nushell: 'nu' };

function activate(context) {
  const legend = new vscode.SemanticTokensLegend(types);
  const index = new Map(types.map((type, i) => [type, i]));
  const log = vscode.window.createOutputChannel('Vim Highlight');
  let warned = false;

  // Protokoll zur Fehlersuche: Ausgabekanal und protokoll.txt im Erweiterungsordner
  const logFile = path.join(__dirname, 'protokoll.txt');
  const note = (message) => {
    log.appendLine(message);
    try {
      fs.appendFileSync(logFile, `${new Date().toISOString()} ${message}\n`);
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
    const groups = vscode.workspace.getConfiguration('vimHighlight', document.uri).get('backgroundGroups') || [];
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
    if (theme || event.affectsConfiguration('vimHighlight.backgroundGroups')) {
      if (theme) note(`Farbschema: ${activeTheme()}`);
      cache.clear();
      vscode.window.visibleTextEditors.forEach(decorate);
      changed.fire();
    }
  }), vscode.window.onDidChangeVisibleTextEditors((editors) => editors.forEach(decorate)),
  vscode.workspace.onDidCloseTextDocument((document) => cache.delete(document.uri.toString())));

  const provider = {
    onDidChangeSemanticTokens: changed.event,
    async provideDocumentSemanticTokens(document, cancel) {
      const theme = activeTheme();
      const current = themes[theme];
      if (!current) {
        forget(document);
        return null;
      }

      const config = vscode.workspace.getConfiguration('vimHighlight', document.uri);
      const name = path.basename(document.fileName);
      note(`Anfrage: ${name} (${document.languageId}, ${document.lineCount} Zeilen)`);
      if (document.lineCount > config.get('maxLines')) {
        forget(document);
        return null;
      }
      const version = document.version;

      const abort = new AbortController();
      const subscription = cancel.onCancellationRequested(() => abort.abort());
      try {
        const tokens = await highlight({
          vimPath: config.get('vimPath'),
          text: document.getText(),
          fileName: document.fileName,
          filetype: FILETYPES[document.languageId] ?? document.languageId,
          scheme: current.scheme,
          background: current.background,
          signal: abort.signal,
        });
        const builder = new vscode.SemanticTokensBuilder(legend);
        for (const t of tokens) {
          if (index.has(t.type)) builder.push(t.line, t.start, t.length, index.get(t.type), 0);
        }
        // Ergebnisse zu einem inzwischen geaenderten Text wuerden verrutschen
        const upToDate = !cancel.isCancellationRequested && document.version === version && theme === activeTheme();
        const marked = upToDate ? remember(document, version, theme, tokens) : 0;
        note(`${name}: ${tokens.length} Abschnitte von Vim, ` +
          `${tokens.filter((t) => index.has(t.type)).length} davon mit bekannter Gruppe, ${marked} Hintergruende`);
        return builder.build();
      } catch (error) {
        if (!cancel.isCancellationRequested) {
          note(String(error.message || error));
          if (!warned) {
            warned = true;
            vscode.window.showWarningMessage('Vim Highlight: Vim konnte nicht ausgefuehrt werden (siehe Ausgabe).');
          }
        }
        return null;
      } finally {
        subscription.dispose();
      }
    },
  };

  const selector = [
    ...LANGUAGES.flatMap((language) => [
      { scheme: 'file', language },
      { scheme: 'untitled', language },
    ]),
    ...EXTENSIONS.map((extension) => ({ scheme: 'file', pattern: `**/*.${extension}` })),
  ];
  context.subscriptions.push(
    log,
    vscode.languages.registerDocumentSemanticTokensProvider(selector, provider, legend)
  );
}

module.exports = { activate };
