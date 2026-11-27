'use strict';
// Faerbt ohne Vim, allein aus den Daten in syntaxdaten und schemata. Bildet Vims
// Syntax-Maschine nach (syntax.c) und die Vim-Suchmuster, soweit die Regeln sie brauchen.
// Gemessen wird mit werkzeuge/ohne-vim-messen.js.
const fs = require('fs');
const path = require('path');

class Unsupported extends Error {}

// ---- Vim-Muster -> JavaScript ------------------------------------------------

// Zeichenarten wie in Vim (utf_class). Bis Zeichen 255 zaehlt 'iskeyword' (je Syntax),
// darueber ist alles ein Wortzeichen, was nicht Leerraum oder Satzzeichen ist.
const HIGH = '[\\u0100-\\u{10ffff}]';
const PUNCT = '\\u037e\\u0387\\u055a-\\u055f\\u0589\\u05be\\u05c0\\u05c3\\u05f3\\u05f4\\u060c\\u061b\\u061f' +
  '\\u066a-\\u066d\\u06d4\\u0700-\\u070d\\u0964\\u0965\\u0970\\u0df4\\u0e4f\\u0e5a\\u0e5b\\u0f04-\\u0f12\\u0f3a-\\u0f3d' +
  '\\u0f85\\u104a-\\u104f\\u10fb\\u1361-\\u1368\\u166d\\u166e\\u1680\\u169b\\u169c\\u16eb-\\u16ed\\u1735\\u1736' +
  '\\u17d4-\\u17dc\\u1800-\\u180a\\u2000-\\u206f\\u20a0-\\u2125\\u2127-\\u2129\\u212c-\\u27ff\\u2900-\\u2998\\u29d8-\\u29db\\u29fc\\u29fd' +
  '\\u2e00-\\u2e7f\\u3000-\\u3020\\u3030\\u303d\\ufd3e\\ufd3f\\ufe30-\\ufe6b\\uff00-\\uff0f\\uff1a-\\uff20' +
  '\\uff3b-\\uff40\\uff5b-\\uff65\\u{1d000}-\\u{1d24f}\\u{1d400}-\\u{1d7ff}\\u{1f000}-\\u{1f2ff}';
// (U+2126, U+212A und U+212B fehlen: ohne Gross/Klein wuerden sie auch gewoehnliche Buchstaben treffen.)
// Arten mit eigener Wortgrenze: hoch- und tiefgestellt, Braille, Hiragana, Katakana, CJK, Hangul
const SCRIPTS = ['\\u2070-\\u207f', '\\u2080-\\u2094', '\\u2800-\\u28ff', '\\u3040-\\u309f', '\\u30a0-\\u30ff',
  '\\u3300-\\u9fff\\uf900-\\ufaff\\u{20000}-\\u{2a6df}\\u{2a700}-\\u{2b81f}\\u{2f800}-\\u{2fa1f}', '\\uac00-\\ud7a3'];
const EMOJI = '(?![\\x00-\\xff])\\p{Extended_Pictographic}';
const OTHERS = [`(?:${EMOJI})`, ...SCRIPTS.map((range) => `[${range}]`)];

// Eine Angabe wie "@,48-57,_,192-255" als Zeichenmenge bis 255
function latinClass(spec) {
  const set = new Set();
  const part = /(\^(?=.))?(\d+|[\s\S])(?:-(\d+|[\s\S]))?(?:,\s*|$)/y;
  for (let m; part.lastIndex < spec.length && (m = part.exec(spec));) {
    const code = (v) => (/^\d+$/.test(v) && v.length > 0 ? Number(v) : v.codePointAt(0));
    const alpha = m[2] === '@' && m[3] === undefined;
    const from = alpha ? 0 : code(m[2]);
    const to = alpha ? 255 : m[3] === undefined ? from : code(m[3]);
    for (let c = from; c <= to && c <= 255; c++) {
      if (alpha && !/[A-Za-zµÀ-ÿ]/.test(String.fromCharCode(c))) continue;
      if (m[1]) set.delete(c); else set.add(c);
    }
  }
  return `[${[...set].map((c) => `\\x${c.toString(16).padStart(2, '0')}`).join('')}]`;
}

// Muster fuer Wortzeichen und Wortgrenzen
const wordCache = new Map();
function wordsFor(spec = '@,48-57,_,192-255') {
  let words = wordCache.get(spec);
  if (!words) {
    const latin = latinClass(spec);
    const key = `(?:${latin}|(?![${PUNCT}])${HIGH})`;
    const word = `(?:${latin}|(?![${PUNCT}${SCRIPTS.join('')}]|\\p{Extended_Pictographic})${HIGH})`;
    // Wortgrenzen \< und \>: auch zwischen zwei verschiedenen Arten
    wordCache.set(spec, words = {
      key,
      start: `(?:(?<!${word})(?=${word})|(?=${HIGH})(?:${OTHERS.map((c) => `(?<!${c})(?=${c})`).join('|')}))`,
      end: `(?:(?<=${word})(?!${word})|(?<=${HIGH})(?:${OTHERS.map((c) => `(?<=${c})(?!${c})`).join('|')}))`,
    });
  }
  return words;
}
const CLASSES = {
  d: '[0-9]', D: '[^0-9\\n]', x: '[0-9A-Fa-f]', X: '[^0-9A-Fa-f\\n]', o: '[0-7]',
  s: '[ \\t]', S: '[^ \\t\\n]', w: '[0-9A-Za-z_]', W: '[^0-9A-Za-z_\\n]',
  // \i und \I nach 'isident': nur Zeichen bis 255
  i: '[A-Za-z0-9_\\u00b5\\u00c0-\\u00ff]', I: '[A-Za-z_\\u00b5\\u00c0-\\u00ff]',
  O: '[^0-7\\n]', a: '[A-Za-z]', A: '[^A-Za-z\\n]', l: '[a-z]', u: '[A-Z]', h: '[A-Za-z_]',
  p: '[^\\x00-\\x1f\\x7f]', f: '[A-Za-z0-9_./\\\\\\-+,#$%~=\\u00c0-\\u{10ffff}]',
};
const NAMED = {
  alpha: 'A-Za-z', alnum: 'A-Za-z0-9', digit: '0-9', xdigit: '0-9A-Fa-f', blank: ' \\t',
  space: ' \\t\\r\\v\\f', upper: 'A-Z', lower: 'a-z', word: '0-9A-Za-z_', punct: '!-\\/:-@\\[-`{-~',
  cntrl: '\\x00-\\x1f\\x7f', print: ' -~\\u00a1-\\u{10ffff}', graph: '!-~', return: '\\r', tab: '\\t',
  escape: '\\x1b', keyword: '0-9A-Za-z_\\u00b5\\u00c0-\\u00ff', ident: '0-9A-Za-z_\\u00b5\\u00c0-\\u00ff',
};
const literal = (c) => (/[\\^$.*+?()[\]{}|\/]/.test(c) ? '\\' + c : c);
const inClass = (c) => (/[\\\]\[^-]/.test(c) ? '\\' + c : c);

// Liest [..] ab Position i (dem "["). null, wenn es keine Zeichenmenge ist.
function collection(p, i, newline) {
  let j = i + 1;
  let negate = false;
  if (p[j] === '^') { negate = true; j++; }
  let body = '';
  if (p[j] === ']') { body += '\\]'; j++; }
  while (j < p.length && p[j] !== ']') {
    const named = /^\[:(\w+):\]/.exec(p.slice(j));
    if (named) {
      if (!NAMED[named[1]]) throw new Unsupported(`[:${named[1]}:]`);
      body += NAMED[named[1]];
      j += named[0].length;
    } else if (p[j] === '\\' && /^(?:d\d|o[0-7]|x[0-9a-fA-F]|u[0-9a-fA-F]|U[0-9a-fA-F])/.test(p.slice(j + 1, j + 3))) {
      // Zeichen als Zahl, z. B. \x7f oder \u2026
      const [all, kind, digits] = /^(?:(d)(\d+)|(o)([0-7]{1,4})|(x)([0-9a-fA-F]{1,2})|(u)([0-9a-fA-F]{1,4})|(U)([0-9a-fA-F]{1,8}))/
        .exec(p.slice(j + 1)).filter((v) => v !== undefined);
      body += `\\u{${parseInt(digits, kind === 'd' ? 10 : kind === 'o' ? 8 : 16).toString(16)}}`;
      j += 1 + all.length;
    } else if (p[j] === '\\' && j + 1 < p.length) {
      const c = p[j + 1];
      const known = { n: '\\n', t: '\\t', r: '\\r', e: '\\x1b', '\\': '\\\\', ']': '\\]', '^': '\\^', '-': '\\-' };
      if (known[c]) { body += known[c]; j += 2; } else { body += '\\\\'; j++; }
    } else if (p[j] === '-' && body && p[j + 1] !== ']') {
      body += '-';
      j++;
    } else {
      body += inClass(p[j]);
      j++;
    }
  }
  if (p[j] !== ']') return null;
  if (negate) body = '^' + body + (newline ? '' : '\\n');
  else if (newline) body += '\\n';
  return { source: `[${body}]`, end: j + 1 };
}

// Zahlen mit Trennzeichen wie \('\=\d\+\)* : Vim prueft das ohne Zuruecksetzen, JavaScript
// wuerde bei langen Ziffernfolgen praktisch endlos probieren. Ohne das innere \+ passt
// dasselbe, nur schnell.
const NESTED = /(\\%?\(\\\('\\\)\\=|\\%?\('\\=)(\\[dxo]|\[01\])\\\+(?=\\\)(?:\*|\\\+))/g;

// Bringt ein Muster in die Schreibweise "magic" (\v, \M, \V gelten ab ihrer Stelle) und liest
// \c und \C aus
function normalize(p) {
  let out = '';
  let mode = 'm';
  let ignoreCase = null;
  let i = 0;
  const literally = (c) => { out += /[.*[^$~\\]/.test(c) ? '\\' + c : c; };
  // Kopiert, was zu \% oder \@ gehoert, unveraendert
  const tail = (regex) => {
    const m = regex.exec(p.slice(i + 1));
    if (m) { out += m[0]; i += m[0].length; }
  };
  const percent = () => {
    if (p[i + 1] === '\\' && p[i + 2] === '(') { out += '\\%('; i += 2; return; }
    out += '\\%';
    tail(/^(?:\(|\^|\$|[<>]?\d+[lcv]|\[(?:\\.|\[[^\]]*\]|[^\]\\])*\]|[A-Za-z#])/);
  };
  const at = () => { out += '\\@'; tail(/^\d*(?:<=|<!|=|!|>)/); };
  // "[" ist hier der Anfang einer Zeichenmenge
  const set = () => {
    const found = collection(p, i, false);
    if (!found) return literally('[');
    out += p.slice(i, found.end);
    i = found.end - 1;
  };
  for (; i < p.length; i++) {
    const c = p[i];
    if (c !== '\\') {
      if (mode === 'v' && '(){|+?=@<>%&'.includes(c)) {
        if (c === '%') percent();
        else if (c === '@') at();
        else out += '\\' + c;
      } else if (c === '[' && (mode === 'v' || mode === 'm')) set();
      else if (mode === 'v' && (c === '^' || c === '$')) out += '\\_' + c;
      else if ((mode === 'v' || mode === 'm') && '.*^$'.includes(c)) out += c;
      else if (mode === 'M' && (c === '^' || c === '$')) out += c;
      else literally(c);
      continue;
    }
    const n = p[++i];
    if (n === undefined) out += '\\';
    else if ('vmMV'.includes(n)) mode = n;
    else if (n === 'c') ignoreCase = true;
    else if (n === 'C') ignoreCase = false;
    else if (n === '%' && mode !== 'v') {
      if (/^#=\d/.test(p.slice(i + 1))) i += 3; // Wahl der Suchmaschine
      else percent();
    } else if (n === '@' && mode !== 'v') at();
    else if (n === 'z') {
      if (p[i + 1] === '\\' && p[i + 2] === '(') { out += '\\z('; i += 2; } else out += '\\z' + (p[++i] ?? '');
    } else if (n === '_') {
      out += '\\_';
      if (p[++i] === '[') set(); else out += p[i] ?? '';
    } else if (/[A-Za-z0-9]/.test(n)) out += '\\' + n;
    else if ((mode === 'V' && '.*^$['.includes(n)) || (mode === 'M' && '.*['.includes(n))) {
      if (n === '[') set(); else out += n;
    } else if (mode === 'v') literally(n);
    else out += '\\' + n;
  }
  return { body: out, ignoreCase };
}

// "external": was die Klammern \z( \) des Anfangs erfasst haben, fuer \z1 in "skip" und "end"
function translate(source, external = [], words = wordsFor()) {
  const classes = { ...CLASSES, k: words.key, K: `(?![0-9])${words.key}` };
  const pattern = source.replace(NESTED, '$1$2');
  let captures = 0;
  let groups = 0; // Nummern der Klammern \( \), fuer \1 bis \9
  // Je Ebene eine Gruppe: Zweige, jeder mit seinen Teilen und \zs / \ze
  const branch = () => ({ atoms: [], zs: null, ze: null });
  const stack = [{ open: '', branches: [branch()] }];
  const top = () => stack.at(-1).branches.at(-1);
  const add = (atom) => top().atoms.push(atom);
  const last = () => {
    if (!top().atoms.length) throw new Unsupported('Wiederholung ohne Vorgaenger');
    return top().atoms.length - 1;
  };
  let atomics = 0;
  // \@> : was einmal passt, wird nicht mehr zurueckgenommen
  const atomic = (body) => `(?=(?<a${++atomics}>${body}))\\k<a${atomics}>`;
  // (X\+\|Y)* passt auf dasselbe wie (X\|Y)* , ebenso (X*\|Y)\+ . Vim stoeren die ersten
  // Formen nicht, JavaScript probiert bei ihnen ohne Treffer praktisch endlos
  const plusOf = new Map(); // "X+" -> X
  const starOf = new Map(); // "X*" -> X
  const looseOf = new Map(); // Gruppe -> dieselbe ohne solche \+ und *
  const emptyGroups = new Set(); // Gruppen mit einem Zweig "X*"
  const repeat = (suffix) => {
    const i = last();
    let atom = top().atoms[i];
    if (/^[*+{]/.test(suffix) && !/^\{\d*\}/.test(suffix)) {
      if (suffix === '+' && emptyGroups.has(atom)) suffix = '*';
      atom = looseOf.get(atom) ?? atom;
    }
    const result = `(?:${atom})${suffix}`;
    if (suffix === '+') plusOf.set(result, `(?:${atom})`);
    if (suffix === '*') starOf.set(result, `(?:${atom})`);
    top().atoms[i] = result;
  };
  let leads = 0; // Anzahl der Teile vor \zs, als benannte Gruppen lead0, lead1 ...
  const render = (group, lookaround) => group.branches.map((b) => {
    if (group !== stack[0]) {
      if (b.zs !== null && !lookaround) throw new Unsupported('\\zs innerhalb einer Gruppe');
      if (b.ze === null || lookaround) return b.atoms.join('');
      // \ze in einer Gruppe: Was folgt, wird nur geprueft (richtig, wenn die Gruppe am Ende steht)
      return b.atoms.slice(0, b.ze).join('') + `(?=${b.atoms.slice(b.ze).join('')})`;
    }
    const from = b.zs ?? 0;
    const to = b.ze ?? b.atoms.length;
    return (from ? `(?<=(?<lead${leads++}>${b.atoms.slice(0, from).join('')}))` : '') + b.atoms.slice(from, to).join('') +
      (to < b.atoms.length ? `(?=${b.atoms.slice(to).join('')})` : '');
  }).join('|');

  for (let i = 0; i < pattern.length; i++) {
    const c = pattern[i];
    if (c === '.') add('[^\\n]');
    else if (c === '*' && top().atoms.length) repeat('*');
    else if (c === '^' && !top().atoms.length) add('^');
    else if (c === '$' && (i === pattern.length - 1 || /^\\[|)]/.test(pattern.slice(i + 1)))) add('$');
    else if (c === '[') {
      const set = collection(pattern, i, false);
      if (set) { add(set.source); i = set.end - 1; } else add('\\[');
    } else if (c !== '\\') add(literal(c));
    else {
      const n = pattern[++i];
      if (n === '(') stack.push({ open: `(?<p${++groups}>`, branches: [branch()] });
      else if (/[1-9]/.test(n) && Number(n) <= groups) add(`\\k<p${n}>`);
      else if (n === 'g') add('g');
      else if (n === 'z' && pattern[i + 1] === '(') { i++; stack.push({ open: `(?<zx${++captures}>`, branches: [branch()] }); }
      else if (n === 'z' && /[1-9]/.test(pattern[i + 1])) {
        const value = external[pattern[++i] - 1] || '';
        add(`(?:${[...value].map(literal).join('')})`);
      }
      else if (n === '%' && pattern[i + 1] === '(') { i++; stack.push({ open: '(?:', branches: [branch()] }); }
      else if (n === ')') {
        const group = stack.pop();
        if (!group || !stack.length) throw new Unsupported('Klammern');
        const ahead = /^\\@\d*(=|!|<=|<!|>)/.exec(pattern.slice(i + 1));
        const body = render(group, !!ahead);
        if (ahead) {
          // Eine nummerierte Klammer behaelt ihre Nummer auch in der Vorschau
          const inner = ahead[1] === '=' && group.open.startsWith('(?<p') ? `${group.open}${body})` : body;
          add(ahead[1] === '>' ? atomic(body) : `(?${ahead[1]}${inner})`);
          i += ahead[0].length;
        } else {
          const result = `${group.open}${body})`;
          let changed = false;
          let empty = false; // ein Zweig "X*": die Gruppe darf dann auch keinmal vorkommen
          const loose = group.branches.map((b) => {
            const atom = b.atoms.length === 1 && b.zs === null && b.ze === null ? b.atoms[0] : null;
            const only = atom && (plusOf.get(atom) ?? starOf.get(atom) ?? looseOf.get(atom));
            if (only) changed = true;
            if (atom && (starOf.has(atom) || emptyGroups.has(atom))) empty = true;
            return only || b.atoms.join('');
          });
          if (changed && group.branches.every((b) => b.zs === null && b.ze === null)) {
            looseOf.set(result, `${group.open}${loose.join('|')})`);
            if (empty) emptyGroups.add(result);
          }
          add(result);
        }
      } else if (n === '|') stack.at(-1).branches.push(branch());
      else if (n === '+') repeat('+');
      else if (n === '=' || n === '?') repeat('?');
      else if (n === '{') {
        const m = /^(-?)(\d*)(,?)(\d*)\\?\}/.exec(pattern.slice(i + 1));
        if (!m) throw new Unsupported('\\{');
        const [all, lazy, min, comma, max] = m;
        const count = comma || (!min && !max) ? `{${min || 0},${max}}` : `{${min}}`;
        repeat(count + (lazy ? '?' : ''));
        i += all.length;
      } else if (n === '@') {
        // Die Zahl in \@123<= begrenzt bei Vim nur, wie weit zurueck gesucht wird
        const m = /^\d*(=|!|<=|<!|>)/.exec(pattern.slice(i + 1));
        if (!m) throw new Unsupported('\\@' + pattern[i + 1]);
        const k = last();
        top().atoms[k] = m[1] === '>' ? atomic(top().atoms[k]) : `(?${m[1]}${top().atoms[k]})`;
        i += m[0].length;
      } else if (n === '<') add(words.start);
      else if (n === '>') add(words.end);
      else if (n === 'z' && pattern[i + 1] === 's') { i++; top().zs = top().atoms.length; }
      else if (n === 'z' && pattern[i + 1] === 'e') { i++; top().ze = top().atoms.length; }
      else if (n === '%' && pattern[i + 1] === '[') {
        // \%[abc]: a, ab, abc oder nichts
        const parts = [];
        for (i += 2; i < pattern.length && pattern[i] !== ']'; i++) {
          if (pattern[i] === '[') {
            const set = collection(pattern, i, false);
            parts.push(set.source);
            i = set.end - 1;
          } else if (pattern[i] === '\\') parts.push(classes[pattern[++i]] || literal(pattern[i]));
          else parts.push(literal(pattern[i]));
        }
        add(parts.reduceRight((rest, part) => `(?:${part}${rest})?`, ''));
      } else if (n === '%' && /^[<>]?\d+[lcv]/.test(pattern.slice(i + 1))) {
        // \%7c Spalte, \%1l Zeile; < und > fuer davor und danach
        const [all, which, digits, unit] = /^([<>]?)(\d+)([lcv])/.exec(pattern.slice(i + 1));
        const before = Number(digits) - 1;
        const count = which === '<' ? `{0,${Math.max(0, before - 1)}}` : which === '>' ? `{${before + 1},}` : `{${before}}`;
        add(unit === 'l' ? `(?<=(?<![\\s\\S])(?:[^\\n]*\\n)${count}[^\\n]*)` : `(?<=^.${count})`);
        i += all.length;
      } else if (n === '%' && /^(?:d\d+|x[0-9a-fA-F]{1,2}|u[0-9a-fA-F]{1,4}|U[0-9a-fA-F]{1,8})/.test(pattern.slice(i + 1))) {
        const [all, kind, digits] = /^([dxuU])([0-9a-fA-F]+)/.exec(pattern.slice(i + 1));
        add(`\\u{${parseInt(digits, kind === 'd' ? 10 : 16).toString(16)}}`);
        i += all.length;
      } else if (n === '%' && pattern[i + 1] === '^') { i++; add('(?<![\\s\\S])'); }
      else if (n === '%' && pattern[i + 1] === '$') { i++; add('(?![\\s\\S])'); }
      else if (n === '_') {
        const m = pattern[++i];
        if (m === '[') {
          const set = collection(pattern, i, true);
          add(set.source);
          i = set.end - 1;
        } else if (m === '.') add('[\\s\\S]');
        else if (m === '^') add('^');
        else if (m === '$') add('$');
        else if (classes[m]) add(`(?:${classes[m]}|\\n)`);
        else throw new Unsupported('\\_' + m);
      } else if (classes[n]) add(classes[n]);
      else if (n === 'n') add('\\n');
      else if (n === 't') add('\\t');
      else if (n === 'r') add('\\r');
      else if (n === 'e') add('\\x1b');
      else if (n !== undefined && !/[A-Za-z0-9%&]/.test(n)) add(literal(n));
      else throw new Unsupported('\\' + n);
    }
  }
  if (stack.length !== 1) throw new Unsupported('Klammern');
  return render(stack[0], false);
}

// ---- Befehle lesen -------------------------------------------------------------

// Muster mit beliebigem Trennzeichen ab Position i; Trennzeichen in [..] zaehlt nicht
function readPattern(text, i) {
  const delimiter = text[i];
  let j = i + 1;
  while (j < text.length && text[j] !== delimiter) {
    if (text[j] === '\\') j += 2;
    else if (text[j] === '[') {
      const set = collection(text, j, false);
      j = set ? set.end : j + 1;
    } else j++;
  }
  const body = text.slice(i + 1, j);
  const offsets = /^(?:(?:ms|me|hs|he|rs|re|lc)=(?:[seb](?:[+-]\d+)?|\d+),?)*/.exec(text.slice(j + 1))[0];
  return { body, offsets, end: j + 1 + offsets.length };
}

const FLAGS = new Set(['contained', 'transparent', 'oneline', 'keepend', 'extend', 'excludenl', 'skipwhite',
  'skipnl', 'skipempty', 'display', 'fold', 'conceal', 'concealends']);
// Wie in Vim duerfen um die Kommas Leerzeichen stehen
const LISTS = /^(contains|containedin|nextgroup|add|remove)\s*=\s*((?:[^\s,]*\s*,\s*)*[^\s,]*)/i; // wie in Vim auch "nextGroup"

// Kann das Muster das Zeilenende erfassen?
function hasEol(body) {
  for (let j = 0; j < body.length;) {
    if (body[j] === '\\') {
      if (body[j + 1] === 'n' || (body[j + 1] === '_' && body[j + 2] !== '^')) return true;
      j += 2;
    } else if (body[j] === '[') {
      const set = collection(body, j, false);
      j = set ? set.end : j + 1;
    } else if (body[j] === '$' && /^(?:$|\\[)|&])/.test(body.slice(j + 1))) {
      return true;
    } else j++;
  }
  return false;
}

// Welche Verschiebungen Vim je nach Art des Musters beachtet
const OFFSETS = { match: ['ms', 'me', 'hs', 'he', 'lc'], start: ['ms', 'hs', 'rs', 'lc'], skip: ['me', 'lc'],
  end: ['me', 'he', 're', 'lc'] };

function compile(found, ignoreCase, part, words) {
  let { body, ignoreCase: forced } = normalize(found.body);
  // "\%73c" am Anfang: Vim zaehlt diese Spalte in Bytes. Das kann ein JavaScript-Muster nicht,
  // deshalb bestimmt matches() den Ort selbst und prueft dort den Rest
  const column = /^\\%(\d+)c/.exec(body);
  if (column) body = body.slice(column[0].length);
  const flags = ((forced ?? ignoreCase) ? 'mui' : 'mu') + (column ? 'y' : 'g');
  const pattern = { re: new RegExp(translate(body, [], words), flags), off: null };
  if (column) pattern.column = Number(column[1]);
  if ((part === 'end' || part === 'skip') && /\\z[1-9]/.test(body)) {
    pattern.build = (external) => new RegExp(translate(body, external, words), flags);
  }
  for (const entry of found.offsets.split(',').filter(Boolean)) {
    const [, name, base, delta, count] = /^(\w\w)=(?:([seb])([+-]\d+)?|(\d+))$/.exec(entry);
    if (!OFFSETS[part].includes(name)) continue;
    pattern.off ||= {};
    pattern.off[name] = name === 'lc' ? Number(count) : { base: base === 'e' ? 'e' : 's', delta: Number(delta || 0) };
  }
  // "lc=" setzt auch "ms=", wenn es fehlt
  if (pattern.off?.lc && !pattern.off.ms && (part === 'match' || part === 'start')) {
    pattern.off.ms = { base: 's', delta: pattern.off.lc };
  }
  return pattern;
}

function parseItem(kind, text, ignoreCase, words) {
  const name = /^\S+/.exec(text)[0];
  const item = { kind, name, ignoreCase, start: [], skip: [], end: [], words: [], flags: new Set() };
  let position = name.length;
  let matchgroup = null;
  const regex = (part) => {
    const found = readPattern(text, position);
    position = found.end;
    // Wie in Vim zaehlt "excludenl" nur, wenn es vor dem Muster steht
    if ((part === 'match' || part === 'end') && !item.flags.has('excludenl') && hasEol(normalize(found.body).body)) item.eol = true;
    return compile(found, ignoreCase, part, words);
  };
  while (position < text.length) {
    const rest = text.slice(position);
    const space = /^\s+/.exec(rest);
    if (space) { position += space[0].length; continue; }
    const list = LISTS.exec(rest);
    const option = /^(matchgroup|cchar)=(\S+)/i.exec(rest); // wie in Vim auch "matchGroup"
    const part = kind === 'region' && /^(start|skip|end)\s*=\s*/.exec(rest);
    const word = /^\S+/.exec(rest)[0];
    if (list) {
      const names = list[2].split(/\s*,\s*/).filter(Boolean);
      const key = list[1].toLowerCase();
      // Bei "cluster" wirken alle Angaben nacheinander, sonst gilt wie in Vim die erste
      if (kind === 'cluster') (item.ops ||= []).push([key, names]);
      else item[key] ||= names;
      position += list[0].length;
    }
    else if (option) {
      if (option[1].toLowerCase() === 'matchgroup') matchgroup = option[2] === 'NONE' ? null : option[2];
      position += option[0].length;
    } else if (part) {
      position += part[0].length;
      // Wie in Vim: Heisst die Gruppe des Endes wie die Region selbst, gilt das Ende als
      // eines ohne eigene Gruppe (bei "transparent" bleibt es damit ungefaerbt)
      const own = part[1] === 'end' && matchgroup?.toLowerCase() === name.toLowerCase();
      item[part[1]].push({ ...regex(part[1]), group: own ? null : matchgroup });
    } else if (FLAGS.has(word) && !(kind === 'keyword' && /^(display|fold|extend)$/.test(word))) {
      // Bei "keyword" sind diese drei gewoehnliche Woerter
      item.flags.add(word); position += word.length;
    }
    else if (kind === 'keyword') {
      const optional = /^([^[]+)\[(.*)\]$/.exec(word);
      if (optional) {
        for (let n = 0; n <= optional[2].length; n++) item.words.push(optional[1] + optional[2].slice(0, n));
      } else item.words.push(word);
      position += word.length;
    } else if (kind === 'match' && !item.start.length) item.start.push({ ...regex('match'), group: null });
    else if (word.startsWith('"')) break; // Kommentar
    else throw new Unsupported(`Angabe "${word}"`);
  }
  return item;
}

function load(data) {
  // 'syntax iskeyword' gilt, falls gesetzt, sonst 'iskeyword' des Dateityps
  const set = /^syntax iskeyword (?!not set)(\S+)/.exec((data.syntaxIskeyword || '').trim());
  const spec = set ? set[1] : data.iskeyword;
  const words = wordsFor(spec);
  const items = [];
  const clusters = new Map(); // Namen in Kleinbuchstaben: Vim unterscheidet Gross/Klein nicht
  const skipped = [];
  const includes = []; // Die gerade offenen "syntax include": Cluster und laufende Nummer
  let included = 0;
  // Listen merken, in welcher Datei sie stehen: ALL, TOP usw. meinen nur deren Gruppen
  const tag = (item) => {
    for (const key of ['contains', 'containedin', 'nextgroup', 'add', 'remove']) {
      if (item[key]) item[key].tag = includes.at(-1)?.tag ?? 0;
    }
    return item;
  };
  let ignoreCase = false;
  for (const [, command] of data.befehle) {
    const [, verb, rest = ''] = /^(\S+)\s*([\s\S]*)$/.exec(command);
    try {
      if (verb === 'case') ignoreCase = rest.startsWith('ignore');
      else if (verb === 'include') {
        includes.push({ cluster: (/^@(\S+)\s/.exec(rest) || [])[1]?.toLowerCase() ?? null, tag: ++included });
      }
      else if (verb === 'include-end') includes.pop();
      else if (verb === 'cluster') {
        const item = parseItem('cluster', rest, ignoreCase, words);
        const here = includes.at(-1)?.tag ?? 0;
        let members = clusters.get(item.name.toLowerCase()) || [];
        for (const [op, names] of item.ops || []) {
          const lower = new Set(names.map((m) => m.toLowerCase()));
          const next = op === 'contains' ? [...names]
            : op === 'add' ? [...members, ...names]
              : members.filter((m) => !lower.has(m.toLowerCase()));
          members = Object.assign(next, { tag: op === 'contains' ? here : members.tag ?? here });
        }
        clusters.set(item.name.toLowerCase(), members);
      } else if (verb === 'clear') {
        const names = new Set(rest.split(/\s+/).filter(Boolean).map((n) => n.toLowerCase()));
        for (let i = items.length - 1; i >= 0; i--) {
          if (!names.size || names.has(items[i].name.toLowerCase())) items.splice(i, 1);
        }
        for (const name of names) if (name.startsWith('@')) clusters.delete(name.slice(1));
        if (!names.size) clusters.clear();
      } else if (['match', 'region', 'keyword'].includes(verb)) {
        const item = tag(parseItem(verb, rest, ignoreCase, words));
        const include = includes.at(-1);
        item.tag = include?.tag ?? 0;
        item.top = !item.flags.has('contained'); // oben in seiner Datei
        if (include?.cluster && item.top) {
          item.flags.add('contained');
          const old = clusters.get(include.cluster) || [];
          clusters.set(include.cluster, Object.assign([...old, item.name], { tag: old.tag }));
        }
        items.push(item);
      } else if (!['sync', 'spell', 'iskeyword', 'conceal', 'foldlevel'].includes(verb)) {
        throw new Unsupported(`Befehl ${verb}`);
      }
    } catch (error) {
      if (!(error instanceof Unsupported) && !(error instanceof SyntaxError)) throw error;
      skipped.push({ command, reason: error.message });
    }
  }
  return { items, clusters, skipped, words };
}

// ---- Regeln anwenden -------------------------------------------------------------

// Token-Namen in VS Code duerfen nur Buchstaben, Ziffern, _ und - enthalten
const tokenType = (group) => 'vim_' + group.replace(/[^A-Za-z0-9_-]/g, '_');

const MAXCOL = 3000; // Wie Vim ('synmaxcol'): weiter rechts wird nicht gefaerbt

function highlighter(data) {
  const { items, clusters, skipped, words } = load(data);
  const patterns = items.flatMap((item) => [...item.start, ...item.skip, ...item.end]);

  // Ein Eintrag wie "rubyNested.\+" ist ein Vim-Muster fuer Gruppennamen
  const namePatterns = new Map();
  const fits = (entry, name) => {
    if (!/[.*[\\^$~]/.test(entry)) return false;
    if (!namePatterns.has(entry)) {
      const plain = entry.replace(/\\([+=?|(){])/g, (_, c) => (c === '=' ? '?' : c));
      namePatterns.set(entry, new RegExp(`^(?:${plain})$`, 'i'));
    }
    return namePatterns.get(entry).test(name);
  };

  // Steht die Regel in der Liste? Wie in Vim: Beginnt die Liste mit ALL, ALLBUT, TOP oder
  // CONTAINED, zaehlt alles ausser dem, was folgt, aber nur aus derselben Datei
  const listed = (list, item, depth = 0) => {
    const first = list[0];
    let wanted = true;
    let from = 0;
    if (first === 'ALL' || first === 'ALLBUT' || first === 'TOP' || first === 'CONTAINED') {
      if (item.tag !== (list.tag ?? 0)) return false;
      if (first === 'TOP' && !item.top) return false;
      if (first === 'CONTAINED' && item.top) return false;
      wanted = false;
      from = 1;
    }
    for (let i = from; i < list.length; i++) {
      const entry = list[i];
      if (entry.startsWith('@')) {
        const members = clusters.get(entry.slice(1).toLowerCase());
        if (members && depth < 30 && listed(members, item, depth + 1)) return wanted;
      } else if (entry.toLowerCase() === item.name.toLowerCase() || fits(entry, item.name)) {
        return wanted;
      }
    }
    return !wanted;
  };

  // Aus einer Liste von Regeln (zuletzt Definiertes zuerst): Muster und Nachschlagetafel
  const context = (list) => {
    const words = new Map();
    const folded = new Map(); // Schluesselwoerter ohne Gross/Klein
    for (const item of list) {
      if (item.kind !== 'keyword') continue;
      for (const word of item.words) {
        const map = item.ignoreCase ? folded : words;
        const key = item.ignoreCase ? word.toLowerCase() : word;
        if (!map.has(key)) map.set(key, item);
      }
    }
    return { rules: list.filter((item) => item.kind !== 'keyword'), words, folded };
  };

  // Welche Regeln duerfen innerhalb von "frame" beginnen?
  const inside = new Map();
  const allowed = (stack) => {
    let i = stack.length - 1;
    while (i >= 0 && stack[i].item.flags.has('transparent') && !stack[i].item.contains) i--;
    const key = i >= 0 ? stack[i].item : null;
    let found = inside.get(key);
    if (!found) {
      inside.set(key, found = context(items.filter((item) => {
        if (!key) return !item.flags.has('contained');
        if (item.containedin && listed(item.containedin, key)) return true;
        return !!key.contains && listed(key.contains, item);
      }).reverse()));
    }
    return found;
  };
  const afterwards = new Map(); // nextgroup-Liste -> Regeln
  const following = (list) => {
    let found = afterwards.get(list);
    if (!found) afterwards.set(list, found = context(items.filter((i) => listed(list, i)).reverse()));
    return found;
  };

  // Gruppe, auf die am Ende verwiesen wird, in der Schreibweise von Vim.
  // "eigene": wo das gewaehlte Farbschema eine Gruppe anders zuordnet
  const links = new Map(Object.entries(data.gruppen).map(([name, to]) => [name.toLowerCase(), { name, to }]));
  // Je Farbschema eine eigene Tabelle Gruppe -> Tokenart
  const schemes = new Map();
  const typesFor = (key) => {
    let type = schemes.get(key);
    if (!type) {
      const own = new Map(Object.entries(data.schemata?.[key] || {}).map(([g, to]) => [g.toLowerCase(), to]));
      const types = new Map();
      schemes.set(key, type = (group) => {
        let found = types.get(group);
        if (!found) {
          let name = own.get(group.toLowerCase());
          if (!name) {
            name = group;
            for (let n = 0; n < 20; n++) {
              const entry = links.get(name.toLowerCase());
              if (entry) name = entry.name;
              if (!entry?.to) break;
              name = entry.to;
            }
          }
          types.set(group, found = tokenType(name));
        }
        return found;
      });
    }
    return type;
  };

  // Gibt es Regionen mit "keepend", deren Ende "he=" hat? Nur dann lohnt die Pruefung je Zeichen
  const hiding = items.some((item) => item.flags.has('keepend') && item.end.some((p) => p.off?.he));

  const isWord = new RegExp(words.key, 'uy');
  const afterWord = new RegExp(`(?<=${words.key})`, 'uy');
  const sticky = (regex, text, pos) => {
    regex.lastIndex = pos;
    const m = regex.exec(text);
    return m ? pos + m[0].length : -1;
  };

  return {
    skipped,
    // Wie vim.js: Abschnitte je Zeile mit der Gruppe, auf die am Ende verwiesen wird
    highlight(source, { scheme = 'default', background = 'light' } = {}) {
      const type = typesFor(`${scheme} ${background}`);
      const text = source.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').replace(/\n$/, '');
      for (const p of patterns) p.from = -1;
      const built = new Map(); // Muster mit \z1, je erfasstem Text
      const withExternal = (list, external) => list.map((p) => {
        if (!p.build) return p;
        let found = built.get(p);
        if (!found) built.set(p, found = new Map());
        const key = external.join('\n');
        if (!found.has(key)) found.set(key, { ...p, re: p.build(external), build: null, from: -1 });
        return found.get(key);
      });

      // Erster Treffer ab pos, der in Spalte p.column beginnt (in Bytes gezaehlt)
      const atColumn = (p, pos) => {
        for (let i = pos > 0 ? text.lastIndexOf('\n', pos - 1) + 1 : 0; i <= text.length;) {
          let at = i;
          for (let bytes = 1; bytes < p.column; ) {
            const code = text.codePointAt(at);
            if (code === undefined || code === 10) { at = -1; break; }
            bytes += code < 0x80 ? 1 : code < 0x800 ? 2 : code < 0x10000 ? 3 : 4;
            at += code < 0x10000 ? 1 : 2;
            // Liegt die Spalte mitten in einem Zeichen, passt hier nichts
            if (bytes > p.column) { at = -1; break; }
          }
          if (at >= pos) {
            p.re.lastIndex = at;
            const m = p.re.exec(text);
            if (m) return m;
          }
          const eol = text.indexOf('\n', i);
          if (eol < 0) break;
          i = eol + 1;
        }
        return null;
      };

      // Passt das Muster bei pos? Der naechste Treffer wird gemerkt, damit nicht jede
      // Stelle neu durchsucht werden muss.
      const matches = (p, pos) => {
        if (p.from < 0 || pos < p.from || (p.index >= 0 && p.index < pos)) {
          p.re.lastIndex = pos;
          const m = p.column ? atColumn(p, pos) : p.re.exec(text);
          p.from = pos;
          p.index = m ? m.index : -1;
          if (m) {
            p.length = m[0].length;
            p.lead = 0; // Laenge des Teils vor \zs
            p.external = []; // Erfasstes aus \z( \)
            for (const [key, value] of Object.entries(m.groups || {})) {
              if (key.startsWith('lead')) p.lead = Math.max(p.lead, value?.length || 0);
              else if (key.startsWith('zx')) p.external[key.slice(2) - 1] = value || '';
            }
          }
        }
        return p.index === pos;
      };
      // Um Zeichen verschieben, innerhalb der Zeile. Vim zaehlt Zeichen, JavaScript zaehlt
      // halbe Ersatzpaare
      const shift = (at, delta) => {
        for (; delta < 0 && at > 0 && text[at - 1] !== '\n'; delta++) at -= /[\udc00-\udfff]/.test(text[at - 1]) ? 2 : 1;
        for (; delta > 0 && at < text.length && text[at] !== '\n'; delta--) at += /[\ud800-\udbff]/.test(text[at]) ? 2 : 1;
        return at;
      };
      // Wie syn_add_start_off und syn_add_end_off in Vim; s und e sind Anfang und Ende des Treffers
      const startOff = (s, e, off) => (!off ? s : off.base === 's' ? shift(s, off.delta) : shift(e, off.delta - 1));
      const endOff = (s, e, off, extra) => (!off ? e : off.base === 's' ? shift(s, off.delta + extra) : shift(e, off.delta));

      // Beginnt bei pos eine Regel mit diesem Muster? "from": ab hier ist die Zeile noch frei.
      // Ergebnis: Anfang und Ende des Treffers
      const startsAt = (p, pos, from) => {
        const ms = p.off?.ms;
        const lc = p.off?.lc || 0;
        const limit = lc ? shift(from, -lc) : from;
        if (!ms) {
          return matches(p, pos) && pos - p.lead >= limit ? [pos, pos + p.length] : null;
        }
        if (ms.base === 's') {
          const raw = shift(pos, -ms.delta);
          return raw >= limit && shift(raw, ms.delta) === pos && matches(p, raw) ? [raw, raw + p.length] : null;
        }
        // "ms=e": der erste Treffer ab der freien Stelle
        const at = Math.max(limit, text.lastIndexOf('\n', pos - 1) + 1);
        matches(p, at); // merkt den naechsten Treffer, auch wenn er spaeter liegt
        if (p.index < 0 || startOff(p.index, p.index + p.length, ms) !== pos) return null;
        return [p.index, p.index + p.length];
      };

      // Findet sich hier das Ende der Region? Was "skip" erfasst, zaehlt dafuer nicht.
      const regionEnd = (frame, pos) => {
        if (frame.closing || pos < frame.noEnd) return null;
        for (const p of frame.skips || frame.item.skip) {
          if (!matches(p, pos)) continue;
          let to = endOff(p.index, p.index + p.length, p.off?.me, 1);
          // Reicht "skip" bis ans Zeilenende, geht die Suche in der naechsten Zeile weiter
          if (to >= text.length || text[to] === '\n') to++;
          if (to > pos) { frame.noEnd = to; return null; }
        }
        return (frame.ends || frame.item.end).find((p) => matches(p, pos)) || null;
      };
      const startClosing = (frame, p) => {
        const s = p.index;
        const e = p.index + p.length;
        const off = p.off || {};
        const stop = endOff(s, e, off.me, 1);
        const lit = Math.min(endOff(s, e, off.he, 1), stop);
        frame.closing = true;
        frame.endGroup = p.group;
        if (p.group) {
          // Bis "re" gehoert der Text noch zur Region, danach zur Gruppe des Endes
          frame.re = Math.min(off.re ? shift(off.re.base === 'e' ? e : s, off.re.delta) : s, stop);
          frame.end = Math.max(frame.re, lit);
          frame.hend = undefined;
        } else {
          frame.end = stop;
          frame.hend = lit;
        }
      };

      // Passt das Ende erst leer am Zeilenende und reicht "he=" davor zurueck, bleibt das
      // letzte Zeichen der Zeile ungefaerbt (Vim kennt das Ende schon vorher)
      const hiddenBeforeEnd = (frame, pos) => {
        if (frame.item.kind !== 'region' || frame.closing || text[pos + 1] !== '\n') return false;
        const p = (frame.ends || frame.item.end).find((end) => matches(end, pos + 1));
        return !!p?.off?.he && endOff(p.index, p.index + p.length, p.off.he, 1) <= pos;
      };

      // "oneline": die Region beginnt nur, wenn ihr Ende in derselben Zeile liegt
      const endsOnLine = (frame) => {
        const probe = { ...frame };
        for (let p = frame.noEnd; p <= text.length; p++) {
          if (regionEnd(probe, p)) return true;
          if (text[p] === '\n') return false;
        }
        return false;
      };

      const keywordAt = (set, pos) => {
        if (!set.words.size && !set.folded.size) return null;
        if (sticky(isWord, text, pos) < 0 || sticky(afterWord, text, pos) >= 0) return null;
        let end = pos;
        for (let to = sticky(isWord, text, end); to >= 0; to = sticky(isWord, text, end)) end = to;
        const word = text.slice(pos, end);
        const item = set.words.get(word) || (set.folded.size && set.folded.get(word.toLowerCase()));
        return item ? { item, from: pos, end } : null;
      };

      // Welche Regel beginnt hier? "from": ab hier ist die Zeile noch frei, auch fuer den
      // Teil vor \zs
      const find = (set, stack, pos, from) => {
        const open = (item) => stack.some((f) => f.item === item && f.from === pos) || zero.has(item);
        const keyword = keywordAt(set, pos);
        if (keyword && !open(keyword.item)) return keyword;
        for (const item of set.rules) {
          for (const start of item.start) {
            const found = startsAt(start, pos, from);
            if (!found || open(item)) continue;
            const [s, e] = found;
            const off = start.off || {};
            const hs = off.hs ? Math.max(pos, startOff(s, e, off.hs)) : pos;
            if (item.kind === 'match') {
              const end = endOff(s, e, off.me, 0);
              // Wie in Vim darf der Treffer leer sein (fuer "nextgroup")
              if (end >= pos) return { item, from: pos, end, hs, hend: Math.min(endOff(s, e, off.he, 0), end) };
            } else {
              // "rs=": so weit reicht die Gruppe des Anfangs; das Ende wird hinter dem Treffer gesucht
              const content = endOff(s, e, off.rs, 0);
              // Geht der Anfang ueber das Zeilenende, sucht Vim in der ersten Zeile weiter,
              // und zwar ab der Spalte, in der der Treffer endet
              let after = e;
              const eol = text.indexOf('\n', s);
              if (eol >= 0 && e > eol) {
                after = Math.min(eol, text.lastIndexOf('\n', s) + 1 + e - (text.lastIndexOf('\n', e - 1) + 1));
              }
              const frame = { item, from: pos, content, hs, startGroup: start.group, noEnd: after, closing: false };
              matches(start, s);
              if (start.external?.length) {
                frame.skips = withExternal(item.skip, start.external);
                frame.ends = withExternal(item.end, start.external);
              }
              if (!item.flags.has('oneline') || endsOnLine(frame)) return frame;
            }
          }
        }
        return null;
      };

      const tokens = [];
      const stack = [];
      let next = null; // nextgroup nach dem Ende einer Regel
      let line = 0;
      let lineStart = 0;
      let byte = 0; // Spalte in UTF-8-Bytes, wie Vim sie zaehlt
      let open = null;
      let searchFrom = 0;
      let here = 0;
      const zero = new Set(); // Regeln, die an dieser Stelle schon leer gepasst haben
      const close = () => {
        searchFrom = here;
        const frame = stack.pop();
        // Wie in Vim: Enden mehrere Regeln hier, zaehlt "nextgroup" der aeussersten
        next = frame.item.nextgroup ? { list: frame.item.nextgroup, flags: frame.item.flags } : null;
        // Wie in Vim: Nach einer enthaltenen Regel wird das Ende einer Region von hier an neu
        // gesucht; bei "keepend" steht es fest
        const top = stack.at(-1);
        if (top && top.item.kind === 'region' && !top.closing && !top.item.flags.has('keepend')) {
          top.noEnd = here;
          // Reichte die enthaltene Regel bis ans Zeilenende, geht die Region weiter
          if (frame.item.eol && text[here] === '\n' && !stack.some((f) => f.item.flags.has('keepend'))) {
            // Ausser das Ende nimmt den Zeilenumbruch selbst mit
            const probe = { ...top };
            const end = regionEnd(probe, here);
            if (end) startClosing(probe, end);
            if (!end || probe.end <= here) top.noEnd = here + 1;
          }
        }
      };

      for (let pos = 0; pos < text.length;) {
        if (pos !== here) zero.clear();
        here = pos;
        // 1. "keepend": Das Ende einer solchen Region beendet auch alles, was in ihr offen
        // ist, ausser darueber liegt eine Regel mit "extend"
        let guard = 0;
        for (let i = stack.length - 1; i >= 0; i--) {
          // Eine Regel, die gerade vor diesem Zeichen endet, schuetzt nicht mehr
          const f = stack[i];
          if (f.item.flags.has('extend') && !(f.end !== undefined && pos >= f.end)) { guard = i + 1; break; }
        }
        for (let i = guard; i < stack.length - 1; i++) {
          const frame = stack[i];
          if (frame.item.kind !== 'region' || !frame.item.flags.has('keepend')) continue;
          if (!frame.closing) {
            const end = regionEnd(frame, pos);
            if (end) startClosing(frame, end);
          }
          // Mit eigener Gruppe fuer das Ende hoert Enthaltenes davor auf, sonst erst dahinter
          if (frame.closing && pos >= (frame.endGroup ? frame.re : frame.end)) {
            stack.length = i + 1;
            searchFrom = pos;
            break;
          }
        }
        // 2. Was endet vor diesem Zeichen?
        for (;;) {
          const top = stack.at(-1);
          if (!top) break;
          if (top.end !== undefined && pos >= top.end) { close(); continue; }
          if (top.item.kind === 'region') {
            if (top.item.flags.has('oneline') && text[pos] === '\n' && !top.closing) { close(); continue; }
            const end = regionEnd(top, pos);
            if (end) { startClosing(top, end); continue; }
          }
          break;
        }
        // 3. Was beginnt hier?
        if (text[pos] === '\n' && next && !next.flags.has('skipnl') && !next.flags.has('skipempty')) next = null;
        // Am Ende einer Zeile beginnt nichts, ausser die Zeile ist leer (wie in Vim)
        while (text[pos] !== '\n' || pos === lineStart) {
          const top = stack.at(-1);
          // Wie in Vim: Ohne eigene Gruppe (matchgroup) fuer Anfang oder Ende koennen
          // enthaltene Regeln auch dort beginnen
          if (top && top.item.kind === 'region') {
            // Wie in Vim: "nextgroup" passt nicht im Muster des Endes
            if (top.closing && top.endGroup && pos >= top.re) { next = null; break; }
            if (pos < top.content && top.startGroup) break;
          }
          if (top && top.item.kind === 'keyword') break;
          let found = null;
          if (next) {
            found = find(following(next.list), stack, pos, searchFrom);
            if (found) next = null;
            else if (!(next.flags.has('skipwhite') && /[ \t]/.test(text[pos]))) next = null;
          }
          found = found || find(allowed(stack), stack, pos, searchFrom);
          if (!found) break;
          // Verbraucht eine enthaltene Regel das Ende, wird es spaeter neu gesucht.
          // Bei "keepend" bleibt das Ende stehen, ausser die Regel hat "extend"
          if (top && top.closing &&
              (!top.item.flags.has('keepend') || found.item.flags.has('extend'))) {
            top.closing = false;
            top.end = undefined;
            top.hend = undefined;
          }
          searchFrom = found.startGroup ? found.content : pos;
          stack.push(found);
          if (found.item.kind === 'keyword') break;
          // Leerer Anfang (start=""): Das Ende kann schon an derselben Stelle liegen
          if (found.item.kind === 'region' && found.content === pos) {
            const end = regionEnd(found, pos);
            if (end) startClosing(found, end);
          }
          if (found.item.kind === 'match' && found.end === pos) {
            zero.add(found.item);
            close();
          }
        }
        // 4. Gruppe dieses Zeichens
        const code = text.charCodeAt(pos);
        if (code === 10) {
          open = null;
          line++;
          lineStart = pos + 1;
          byte = 0;
          searchFrom = Math.max(searchFrom, pos + 1);
          pos++;
          continue;
        }
        const width = code >= 0xd800 && code < 0xdc00 && pos + 1 < text.length ? 2 : 1;
        let group = null;
        // Wie in Vim: "he=" einer Region mit "keepend" gilt auch fuer das darin Enthaltene
        let visible = stack.length - 1;
        for (let i = hiding ? stack.length - 1 : -1; i >= 0; i--) {
          const f = stack[i];
          if (f.item.flags.has('keepend') &&
              (f.hend !== undefined ? pos >= f.hend : hiddenBeforeEnd(f, pos))) visible = i - 1;
          if (f.item.flags.has('extend')) break;
        }
        for (let i = visible; i >= 0 && !group; i--) {
          const f = stack[i];
          if (pos < f.hs) continue; // "hs=": noch nicht gefaerbt
          const region = f.item.kind === 'region';
          if (region && f.startGroup && pos < f.content) group = f.startGroup;
          else if (region && f.closing && f.endGroup && pos >= f.re) group = f.endGroup;
          else if (f.hend !== undefined && pos >= f.hend) continue; // "he="
          else if (!f.item.flags.has('transparent')) group = f.item.name;
        }
        const kind = group && byte < MAXCOL ? type(group) : null;
        byte += width === 2 ? 4 : code < 0x80 ? 1 : code < 0x800 ? 2 : 3;
        const column = pos - lineStart;
        if (open && open.type === kind && open.line === line) open.length += width;
        else if (kind) tokens.push(open = { line, start: column, length: width, type: kind });
        else open = null;
        pos += width;
      }
      return tokens;
    },
  };
}

// Regeln eines Dateityps und, falls vorhanden, die Abweichungen der Farbschemata
function loadData(type) {
  const file = (dir) => path.join(__dirname, dir, `${type}.json`);
  const read = (dir) => JSON.parse(fs.readFileSync(file(dir), 'utf8'));
  const data = read('syntaxdaten');
  if (fs.existsSync(file('schemata'))) data.schemata = read('schemata');
  return data;
}

module.exports = { highlighter, loadData, tokenType };
