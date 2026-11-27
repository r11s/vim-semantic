'use strict';
const fs = require('fs');
const path = require('path');
const vscode = require('vscode');
const { highlight, tokenType } = require('./vim');
const { highlighter, loadData, typeFor } = require('./faerben');
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
  'bas', 'p', 'elm', 'tcc', 'moc'];
// Nur noetig, wenn Vim den Typ nicht am Dateinamen erkennt (etwa bei "Untitled")
const FILETYPES = { shellscript: 'sh', viml: 'vim', csharp: 'cs', powershell: 'ps1',
  'objective-c': 'objc', plaintext: '', bat: 'dosbatch', 'cuda-cpp': 'cuda', cython: 'pyrex',
  standardml: 'sml', smalltalk: 'st', unrealscript: 'uc', ahk: 'autohotkey',
  processing: 'arduino', nushell: 'nu' };

// Versuch: C und C++ faerbt die Erweiterung selbst nach den Regeln aus syntaxdaten, ohne Vim
// zu starten. Den Typ bestimmen wie in Vim der Dateiname und bei ".h" der Inhalt; ohne
// passenden Namen zaehlt bei ungespeicherten Dateien die Sprache.
const UNTITLED = { c: 'c', cpp: 'cpp' };
const ownType = (document, text) => typeFor(document.fileName, text) ??
  ((document.isUntitled && UNTITLED[document.languageId]) || null);
const engines = new Map(); // Dateityp -> Faerber, beim ersten Gebrauch geladen
const ownEngine = (type) => {
  if (!engines.has(type)) engines.set(type, highlighter(loadData(type)));
  return engines.get(type);
};

function activate(context) {
  const legend = new vscode.SemanticTokensLegend(types);
  const index = new Map(types.map((type, i) => [type, i]));
  const log = vscode.window.createOutputChannel('VimSem');
  let warned = false;

  // Protokoll zur Fehlersuche: immer im Ausgabekanal, auf Wunsch (vimHighlight.logFile)
  // auch in protokoll.txt im Erweiterungsordner
  const logFile = path.join(__dirname, 'protokoll.txt');
  const note = (message) => {
    log.appendLine(message);
    if (!vscode.workspace.getConfiguration('vimHighlight').get('logFile')) return;
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
    const settings = ['backgroundGroups', 'vimPath', 'maxLines']
      .some((key) => event.affectsConfiguration(`vimHighlight.${key}`));
    if (theme || settings) {
      if (theme) note(`Farbschema: ${activeTheme()}`);
      if (event.affectsConfiguration('vimHighlight.vimPath')) warned = false;
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
      const text = document.getText();
      const type = ownType(document, text);
      try {
        const start = Date.now();
        const tokens = type
          ? ownEngine(type).highlight(text, { scheme: current.scheme, background: current.background })
          : await highlight({
            vimPath: config.get('vimPath'),
            text,
            fileName: document.fileName,
            filetype: FILETYPES[document.languageId] ?? document.languageId,
            scheme: current.scheme,
            background: current.background,
            signal: abort.signal,
          });
        const time = Date.now() - start;
        const builder = new vscode.SemanticTokensBuilder(legend);
        for (const t of tokens) {
          if (index.has(t.type)) builder.push(t.line, t.start, t.length, index.get(t.type), 0);
        }
        // Ergebnisse zu einem inzwischen geaenderten Text wuerden verrutschen
        const upToDate = !cancel.isCancellationRequested && document.version === version && theme === activeTheme();
        const marked = upToDate ? remember(document, version, theme, tokens) : 0;
        note(`${name}: ${tokens.length} Abschnitte ${type ? `ohne Vim (${type})` : 'von Vim'} in ${time} ms, ` +
          `${tokens.filter((t) => index.has(t.type)).length} davon mit bekannter Gruppe, ${marked} Hintergruende`);
        return builder.build();
      } catch (error) {
        if (!cancel.isCancellationRequested) {
          note(String(error.message || error));
          if (type) {
            // Bewusst kein Ausweichen auf Vim: Beim Versuch soll ein Fehler sichtbar sein
            note(String(error.stack));
            vscode.window.showWarningMessage('VimSem: Faerben ohne Vim fehlgeschlagen (siehe Ausgabe "VimSem").');
          } else if (!warned) {
            warned = true;
            const text = error.code === 'ENOENT'
              ? `VimSem: Vim nicht gefunden ("${config.get('vimPath')}"). Bitte vimHighlight.vimPath setzen.`
              : 'VimSem: Vim konnte nicht ausgefuehrt werden (siehe Ausgabe "VimSem").';
            vscode.window.showWarningMessage(text, 'Einstellung oeffnen').then((choice) => {
              if (choice) vscode.commands.executeCommand('workbench.action.openSettings', 'vimHighlight.vimPath');
            });
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
