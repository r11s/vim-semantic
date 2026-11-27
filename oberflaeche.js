'use strict';
// Farben fuer die Oberflaeche von VS Code ("colors" eines Themes), aus Vims Gruppen.
// Uebernommen aus vim-themes (tools/mktheme.py und tools/mkui.py).
//   Editor     Cursorzeile CursorLine, Zeilennummern LineNr/CursorLineNr, Cursor, Visual,
//              Search/IncSearch, MatchParen, Folded; wie in Vim
//   Flaechen   Editor-Hintergrund und Stufen Richtung Textfarbe (Vim hat keine Seitenleiste)
//   Akzent     Hintergrund von StatusLine, sonst Title, Statement, Constant
//   Dazu       Pmenu/PmenuSel, ErrorMsg/WarningMsg, Diff..., Vims ANSI-Farben im Terminal

// Wie round() in Python (zur geraden Zahl bei .5), damit die Farben denen von vim-themes gleichen
const round = (v) => {
  const low = Math.floor(v);
  return v - low === 0.5 ? low + (low % 2) : Math.round(v);
};
const rgb = (c) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));
const byte = (v) => Math.max(0, Math.min(255, round(v))).toString(16).padStart(2, '0');
const blend = (a, b, t) => {
  const to = rgb(b);
  return `#${rgb(a).map((x, i) => byte(x + (to[i] - x) * t)).join('')}`;
};
const alpha = (c, a) => c.slice(0, 7) + byte(a * 255);
const lum = (c) => {
  const [r, g, b] = rgb(c.slice(0, 7)).map((value) => {
    const v = value / 255;
    return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const contrast = (a, b) => {
  const [high, low] = [lum(a), lum(b)].sort((x, y) => y - x);
  return (high + 0.05) / (low + 0.05);
};
const spread = (c) => Math.max(...rgb(c)) - Math.min(...rgb(c));

// data: { type, foreground, background, groups: { Name: { foreground, background, attributes } },
//         ansi: 16 Farben oder fehlt }
function oberflaeche(data) {
  const NBG = data.background.toLowerCase();
  const NFG = data.foreground.toLowerCase();
  const dark = data.type === 'dark';

  // [fg, bg] einer Gruppe, reverse aufgeloest; null = nicht gesetzt
  const eff = (name) => {
    const group = data.groups[name];
    if (!group) return [null, null];
    const fg = group.foreground.toLowerCase() || null;
    const bg = group.background.toLowerCase() || null;
    const reverse = group.attributes.includes('reverse') || group.attributes.includes('inverse');
    return reverse ? [bg || NBG, fg || NFG] : [fg, bg];
  };
  const fgo = (name) => eff(name)[0];
  const bgo = (name) => eff(name)[1];
  const c = {};

  // ---- Editor: Farben aus Vim
  c['editor.background'] = NBG;
  c['editor.foreground'] = NFG;
  // Hintergruende nur, wenn die Textfarbe darauf lesbar bleibt (Deckkraft: null = voll)
  for (const [key, color, a] of [
    ['editor.lineHighlightBackground', bgo('CursorLine'), null],
    ['editor.selectionBackground', bgo('Visual'), null],
    ['editorBracketMatch.background', bgo('MatchParen'), null],
    ['editor.findMatchBackground', bgo('IncSearch') || bgo('CurSearch'), null],
    ['editor.findMatchHighlightBackground', bgo('Search'), 0.6],
    ['editor.foldBackground', bgo('Folded'), 0.5],
  ]) {
    if (!color || contrast(a ? blend(NBG, color, a) : color, NFG) < 3) continue;
    c[key] = a ? alpha(color, a) : color;
  }
  for (const [key, color] of [
    ['editorCursor.foreground', bgo('Cursor')],
    ['editorLineNumber.foreground', fgo('LineNr')],
    // Wie Vim: ohne eigene Textfarbe in CursorLineNr gilt die von Normal
    ['editorLineNumber.activeForeground', fgo('CursorLineNr') || NFG],
    ['editorWhitespace.foreground', fgo('Whitespace') || fgo('NonText')],
    ['editorRuler.foreground', bgo('ColorColumn')],
    ['editorBracketMatch.border', fgo('MatchParen')],
  ]) {
    if (color) c[key] = color;
  }

  // ---- Oberflaeche
  const far = dark ? '#ffffff' : '#000000'; // Ziel, um Text lesbarer zu machen
  const best = (bg) => (contrast('#ffffff', bg) >= contrast('#000000', bg) ? '#ffffff' : '#000000');
  // fg so weit Richtung Schwarz/Weiss schieben, bis der Kontrast zu bg reicht
  const ensure = (fg, bg, min = 4.5) => {
    if (contrast(fg, bg) >= min) return fg;
    const target = best(bg);
    for (let i = 1; i < 21; i++) {
      const color = blend(fg, target, i / 20);
      if (contrast(color, bg) >= min) return color;
    }
    return target;
  };
  // erste Kandidatin mit genug Kontrast, sonst die erste angepasst
  const pick = (bg, candidates, min = 4.5) =>
    candidates.find((x) => x && contrast(x, bg) >= min) || ensure(candidates[0] || NFG, bg, min);
  const on = (bg) => pick(bg, [NFG, far, best(bg)]); // lesbare Schrift auf bg
  const dim = (bg, min = 4.5) => ensure(blend(NFG, bg, 0.42), bg, min);

  // Kraeftig getoenter Hintergrund (z. B. blue): Stufen bleiben im Farbton
  const max = Math.max(...rgb(NBG));
  const chromatic = max > 0 && spread(NBG) / max > 0.5;
  const target = chromatic ? far : NFG;
  // Stufe zwischen Editor-Hintergrund und Ziel mit mindestens "min" Helligkeitsunterschied
  const surf = (start, min) => {
    for (let t = start; ; t += 0.01) {
      const color = blend(NBG, target, t);
      if (Math.abs(lum(color) - lum(NBG)) >= min || t >= 0.45) return color;
    }
  };

  const side = surf(0.05, 0.008);
  const tabbar = surf(0.09, 0.016);
  const chrome = surf(0.12, 0.022);
  const hover = surf(0.15, 0.03);
  const inact = surf(0.21, 0.045);
  const border = surf(0.24, 0.06);
  const guide = surf(0.14, 0.03);
  const guideActive = surf(0.34, 0.12);
  const field = surf(0.08, 0.014);

  const accent = [bgo('StatusLine'), fgo('Title'), fgo('Statement'), fgo('Constant'), fgo('Identifier')]
    .find((x) => x && contrast(x, NBG) >= 3) || NFG;
  const accentFg = on(accent);
  const accentText = ensure(accent, NBG, 3);

  const debugBg = bgo('ErrorMsg') || '#cc0000';
  const remoteBg = bgo('PmenuSel') || accent;

  // Vorschlagsliste: Pmenu und PmenuSel; sehr kraeftige Pmenu-Farben nur als Toenung
  let pmBg = bgo('Pmenu');
  if (!pmBg || Math.abs(lum(pmBg) - lum(NBG)) < 0.01) pmBg = surf(0.14, 0.03);
  const pmMax = Math.max(...rgb(pmBg));
  if (pmMax > 100 && spread(pmBg) / pmMax > 0.3) pmBg = blend(pmBg, NBG, 0.75);
  const pmFg = pick(pmBg, [fgo('Pmenu'), NFG, far]);
  let psBg = bgo('PmenuSel');
  if (!psBg || contrast(psBg, pmBg) < 1.4) psBg = blend(NBG, accent, 0.45);
  const psFg = pick(psBg, [fgo('PmenuSel'), NFG, far]);

  // Auswahl in Listen: wie PmenuSel, gedaempft
  let listBg = [0.45, 0.4, 0.35, 0.3, 0.25, 0.2, 0.15].map((t) => blend(side, psBg, t))
    .find((x) => contrast(NFG, x) >= 4.5);
  let listFg = NFG;
  if (!listBg) {
    listBg = surf(0.28, 0.06);
    listFg = on(listBg);
  }
  // Menues, Quick-Pick und Fenster im Editor: ruhige Flaeche
  const widgetBg = surf(0.08, 0.014);
  const widgetFg = pick(widgetBg, [NFG, far]);

  const colorful = (x) => x && spread(x) > 90 && contrast(x, NBG) >= 3;
  const err = [bgo('ErrorMsg'), fgo('ErrorMsg'), bgo('Error'), fgo('Error'), '#ff0000'].find(colorful)
    || ensure('#ff0000', NBG, 3);
  const warn = [fgo('WarningMsg'), bgo('WarningMsg'), bgo('Todo'), '#ffa500'].find(colorful)
    || ensure('#ffa500', NBG, 3);
  const info = ensure(fgo('Directory') || accent, NBG, 3);

  const dimSide = dim(side);
  const dimTab = dim(tabbar);
  const selection = c['editor.selectionBackground'];
  const diffAdd = bgo('DiffAdd');
  const diffChange = bgo('DiffChange');
  const diffDelete = bgo('DiffDelete');

  Object.assign(c, {
    'editorError.foreground': err,
    'editorWarning.foreground': warn,
    'editorInfo.foreground': info,
    // Allgemein
    foreground: NFG,
    descriptionForeground: dim(NBG),
    disabledForeground: dim(NBG, 3),
    errorForeground: err,
    focusBorder: accentText,
    'widget.border': border,
    'widget.shadow': alpha('#000000', 0.35),
    'icon.foreground': NFG,
    'textLink.foreground': accentText,
    'textLink.activeForeground': ensure(blend(accent, far, 0.25), NBG, 3),
    'textCodeBlock.background': side,
    'textBlockQuote.background': side,
    'textBlockQuote.border': border,
    'textPreformat.foreground': NFG,
    'textSeparator.foreground': border,
    'scrollbar.shadow': '#00000000',
    'scrollbarSlider.background': alpha(NFG, 0.22),
    'scrollbarSlider.hoverBackground': alpha(NFG, 0.36),
    'scrollbarSlider.activeBackground': alpha(NFG, 0.5),
    'progressBar.background': accentText,
    'badge.background': accent,
    'badge.foreground': accentFg,
    'sash.hoverBorder': accentText,
    // Editor (Ergaenzungen)
    'editorIndentGuide.background1': guide,
    'editorIndentGuide.activeBackground1': guideActive,
    'editorGutter.background': NBG,
    'editorGutter.addedBackground': diffAdd || fgo('DiffAdd') || accent,
    'editorGutter.modifiedBackground': diffChange || fgo('DiffChange') || accent,
    'editorGutter.deletedBackground': diffDelete || fgo('DiffDelete') || err,
    'editorLink.activeForeground': accentText,
    'editor.rangeHighlightBackground': alpha(NFG, 0.08),
    'editorGroup.border': border,
    'editorGroup.dropBackground': alpha(accent, 0.25),
    'editorGroupHeader.tabsBackground': tabbar,
    'editorGroupHeader.noTabsBackground': NBG,
    'editorGroupHeader.tabsBorder': border,
    'editorWidget.background': widgetBg,
    'editorWidget.foreground': widgetFg,
    'editorWidget.border': border,
    'editorHoverWidget.background': widgetBg,
    'editorHoverWidget.foreground': widgetFg,
    'editorHoverWidget.border': border,
    'editorHoverWidget.statusBarBackground': surf(0.2, 0.04),
    'editorSuggestWidget.background': pmBg,
    'editorSuggestWidget.foreground': pmFg,
    'editorSuggestWidget.border': border,
    'editorSuggestWidget.selectedBackground': psBg,
    'editorSuggestWidget.selectedForeground': psFg,
    'editorSuggestWidget.highlightForeground': ensure(accent, pmBg, 3),
    'editorOverviewRuler.border': '#00000000',
    'editorOverviewRuler.background': NBG,
    'minimap.background': NBG,
    'minimapSlider.background': alpha(NFG, 0.16),
    'minimapSlider.hoverBackground': alpha(NFG, 0.26),
    'minimapSlider.activeBackground': alpha(NFG, 0.36),
    'peekView.border': accentText,
    'peekViewEditor.background': side,
    'peekViewEditorGutter.background': side,
    'peekViewResult.background': tabbar,
    'peekViewResult.fileForeground': NFG,
    'peekViewResult.lineForeground': dim(tabbar),
    'peekViewResult.selectionBackground': psBg,
    'peekViewResult.selectionForeground': psFg,
    'peekViewTitle.background': chrome,
    'peekViewTitleLabel.foreground': NFG,
    'peekViewTitleDescription.foreground': dim(chrome),
    'peekViewEditor.matchHighlightBackground': alpha(accent, 0.4),
    'peekViewResult.matchHighlightBackground': alpha(accent, 0.4),
    'diffEditor.insertedTextBackground': alpha(diffAdd || accent, 0.35),
    'diffEditor.removedTextBackground': alpha(diffDelete || err, 0.35),
    'diffEditor.insertedLineBackground': alpha(diffAdd || accent, 0.2),
    'diffEditor.removedLineBackground': alpha(diffDelete || err, 0.2),
    'diffEditor.diagonalFill': alpha(diffChange || NFG, 0.35),
    // Tabs
    'tab.activeBackground': NBG,
    'tab.activeForeground': NFG,
    'tab.activeBorderTop': accentText,
    'tab.inactiveBackground': tabbar,
    'tab.inactiveForeground': dimTab,
    'tab.unfocusedActiveBackground': NBG,
    'tab.unfocusedActiveForeground': dim(NBG),
    'tab.unfocusedInactiveBackground': tabbar,
    'tab.unfocusedInactiveForeground': dim(tabbar, 3.5),
    'tab.border': border,
    'tab.hoverBackground': hover,
    'tab.hoverForeground': on(hover),
    'tab.unfocusedHoverBackground': hover,
    'tab.lastPinnedBorder': border,
    'breadcrumb.foreground': dim(NBG),
    'breadcrumb.focusForeground': NFG,
    'breadcrumb.activeSelectionForeground': NFG,
    'breadcrumb.background': NBG,
    'breadcrumbPicker.background': widgetBg,
    // Seitenleiste, Aktivitaetsleiste, Titelleiste, Panel
    'sideBar.background': side,
    'sideBar.foreground': on(side),
    'sideBar.border': border,
    'sideBarTitle.foreground': on(side),
    'sideBarSectionHeader.background': tabbar,
    'sideBarSectionHeader.foreground': on(tabbar),
    'sideBarSectionHeader.border': border,
    'activityBar.background': chrome,
    'activityBar.foreground': on(chrome),
    'activityBar.inactiveForeground': dim(chrome),
    'activityBar.border': border,
    'activityBar.activeBorder': accentText,
    'activityBarBadge.background': accent,
    'activityBarBadge.foreground': accentFg,
    'titleBar.activeBackground': chrome,
    'titleBar.activeForeground': on(chrome),
    'titleBar.inactiveBackground': tabbar,
    'titleBar.inactiveForeground': dimTab,
    'titleBar.border': border,
    'panel.background': side,
    'panel.border': border,
    'panelTitle.activeForeground': on(side),
    'panelTitle.inactiveForeground': dimSide,
    'panelTitle.activeBorder': accentText,
    'panelSectionHeader.background': tabbar,
    'panelSectionHeader.foreground': on(tabbar),
    'commandCenter.background': tabbar,
    'commandCenter.foreground': on(tabbar),
    'commandCenter.border': border,
    'commandCenter.activeBackground': hover,
    'commandCenter.activeForeground': on(hover),
    // Statuszeile
    'statusBar.background': chrome,
    'statusBar.foreground': on(chrome),
    'statusBar.border': border,
    'statusBar.noFolderBackground': chrome,
    'statusBar.noFolderForeground': on(chrome),
    'statusBar.debuggingBackground': debugBg,
    'statusBar.debuggingForeground': on(debugBg),
    'statusBarItem.hoverBackground': alpha(on(chrome), 0.18),
    'statusBarItem.hoverForeground': on(chrome),
    'statusBarItem.remoteBackground': remoteBg,
    'statusBarItem.remoteForeground': on(remoteBg),
    'statusBarItem.prominentBackground': alpha(on(chrome), 0.25),
    'statusBarItem.prominentForeground': on(chrome),
    'statusBarItem.errorBackground': debugBg,
    'statusBarItem.errorForeground': on(debugBg),
    'statusBarItem.warningBackground': warn,
    'statusBarItem.warningForeground': on(warn),
    // Listen, Baeume, Menues, Eingaben, Knoepfe
    'list.activeSelectionBackground': listBg,
    'list.activeSelectionForeground': listFg,
    'list.focusBackground': listBg,
    'list.focusForeground': listFg,
    'list.focusOutline': accentText,
    'list.inactiveSelectionBackground': inact,
    'list.inactiveSelectionForeground': on(inact),
    'list.inactiveFocusBackground': inact,
    'list.hoverBackground': hover,
    'list.hoverForeground': on(hover),
    'list.highlightForeground': ensure(accent, side, 3),
    'list.dropBackground': alpha(accent, 0.25),
    'list.errorForeground': err,
    'list.warningForeground': warn,
    'tree.indentGuidesStroke': guideActive,
    'menu.background': widgetBg,
    'menu.foreground': widgetFg,
    'menu.selectionBackground': listBg,
    'menu.selectionForeground': listFg,
    'menu.separatorBackground': border,
    'menu.border': border,
    'menubar.selectionBackground': hover,
    'menubar.selectionForeground': on(hover),
    'quickInput.background': widgetBg,
    'quickInput.foreground': widgetFg,
    'quickInputTitle.background': chrome,
    'quickInputList.focusBackground': listBg,
    'quickInputList.focusForeground': listFg,
    'pickerGroup.foreground': ensure(accent, widgetBg, 3),
    'pickerGroup.border': border,
    'dropdown.background': widgetBg,
    'dropdown.foreground': widgetFg,
    'dropdown.border': border,
    'dropdown.listBackground': widgetBg,
    'input.background': field,
    'input.foreground': on(field),
    'input.border': border,
    'input.placeholderForeground': dim(field, 3.5),
    'inputOption.activeBorder': accentText,
    'inputOption.activeBackground': alpha(accent, 0.3),
    'inputOption.activeForeground': NFG,
    'inputValidation.errorBackground': side,
    'inputValidation.errorBorder': err,
    'inputValidation.warningBackground': side,
    'inputValidation.warningBorder': warn,
    'inputValidation.infoBackground': side,
    'inputValidation.infoBorder': info,
    'checkbox.background': field,
    'checkbox.foreground': NFG,
    'checkbox.border': border,
    'button.background': accent,
    'button.foreground': accentFg,
    'button.hoverBackground': blend(accent, far, 0.18),
    'button.secondaryBackground': inact,
    'button.secondaryForeground': on(inact),
    'button.secondaryHoverBackground': hover,
    'toolbar.hoverBackground': hover,
    'toolbar.activeBackground': inact,
    'extensionButton.prominentBackground': accent,
    'extensionButton.prominentForeground': accentFg,
    'extensionButton.prominentHoverBackground': blend(accent, far, 0.18),
    'notifications.background': widgetBg,
    'notifications.foreground': widgetFg,
    'notifications.border': border,
    'notificationCenterHeader.background': chrome,
    'notificationCenterHeader.foreground': on(chrome),
    'notificationLink.foreground': ensure(accent, widgetBg, 3),
    'settings.headerForeground': NFG,
    'settings.modifiedItemIndicator': accentText,
    // Terminal
    'terminal.background': NBG,
    'terminal.foreground': NFG,
    'terminalCursor.foreground': c['editorCursor.foreground'] || NFG,
    'terminal.selectionBackground': selection || alpha(NFG, 0.25),
    'terminal.border': border,
    'terminal.tab.activeBorder': accentText,
  });
  // Ohne eigene Auswahlfarbe gilt die von VS Code; ein Ersatz aus dem Akzent waere kaum lesbar
  if (selection) {
    c['selection.background'] = alpha(selection, 0.9);
    c['editor.inactiveSelectionBackground'] = alpha(selection, 0.5);
  }
  if (data.ansi && data.ansi.length === 16) {
    ['Black', 'Red', 'Green', 'Yellow', 'Blue', 'Magenta', 'Cyan', 'White'].forEach((name, i) => {
      c[`terminal.ansi${name}`] = data.ansi[i].toLowerCase();
      c[`terminal.ansiBright${name}`] = data.ansi[8 + i].toLowerCase();
    });
  }
  return c;
}

module.exports = { oberflaeche, contrast };
