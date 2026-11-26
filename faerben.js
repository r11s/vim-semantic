'use strict';
// Faerbt ohne Vim, allein aus den Daten in syntaxdaten und schemata. Bildet die Teile der
// Syntax-Maschine von Vim nach, die C und JSON brauchen. Andere Sprachen sind nicht
// freigegeben: Erst mit werkzeuge/ohne-vim-messen.js messen.
const fs = require('fs');
const path = require('path');

class Unsupported extends Error {}

// ---- Vim-Muster -> JavaScript ------------------------------------------------

// Wortzeichen wie in Vim: iskeyword "@,48-57,_,192-255", dazu Emoji als eigene Wortart.
// Eine Wortgrenze (\< \>) liegt auch zwischen zwei verschiedenen Wortarten.
const WORD = '[\\p{L}\\p{N}\\p{M}_\u00d7\u00f7]';
const EMOJI = '\\p{Extended_Pictographic}';
const boundary = (make) => `(?:${make(WORD)}|${make(EMOJI)})`;
const CLASSES = {
  d: '[0-9]', D: '[^0-9\\n]', x: '[0-9A-Fa-f]', X: '[^0-9A-Fa-f\\n]', o: '[0-7]',
  s: '[ \\t]', S: '[^ \\t\\n]', w: '[0-9A-Za-z_]', W: '[^0-9A-Za-z_\\n]',
  // \i und \I nach 'isident': nur Zeichen bis 255
  i: '[A-Za-z0-9_\\u00b5\\u00c0-\\u00ff]', I: '[A-Za-z_\\u00b5\\u00c0-\\u00ff]',
  a: '[A-Za-z]', A: '[^A-Za-z\\n]', l: '[a-z]', u: '[A-Z]', h: '[A-Za-z_]', k: WORD,
};
const NAMED = {
  alpha: 'A-Za-z', alnum: 'A-Za-z0-9', digit: '0-9', xdigit: '0-9A-Fa-f', blank: ' \\t',
  space: ' \\t\\r\\v\\f', upper: 'A-Z', lower: 'a-z', word: '0-9A-Za-z_', punct: '!-\\/:-@\\[-`{-~',
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

function translate(pattern) {
  // Je Ebene eine Gruppe: Zweige, jeder mit seinen Teilen und \zs / \ze
  const branch = () => ({ atoms: [], zs: null, ze: null });
  const stack = [{ open: '', branches: [branch()] }];
  const top = () => stack.at(-1).branches.at(-1);
  const add = (atom) => top().atoms.push(atom);
  const last = () => {
    if (!top().atoms.length) throw new Unsupported('Wiederholung ohne Vorgaenger');
    return top().atoms.length - 1;
  };
  const repeat = (suffix) => { const i = last(); top().atoms[i] = `(?:${top().atoms[i]})${suffix}`; };
  let leads = 0; // Anzahl der Teile vor \zs, als benannte Gruppen lead0, lead1 ...
  const render = (group, lookaround) => group.branches.map((b) => {
    if (group !== stack[0] && (b.zs !== null || (b.ze !== null && !lookaround))) {
      throw new Unsupported('\\zs oder \\ze innerhalb einer Gruppe');
    }
    if (group !== stack[0]) return b.atoms.join('');
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
      if (n === '(') stack.push({ open: '(', branches: [branch()] });
      else if (n === '%' && pattern[i + 1] === '(') { i++; stack.push({ open: '(?:', branches: [branch()] }); }
      else if (n === ')') {
        const group = stack.pop();
        if (!group || !stack.length) throw new Unsupported('Klammern');
        const ahead = /^\\@(=|!|<=|<!)/.exec(pattern.slice(i + 1));
        const body = render(group, !!ahead);
        if (ahead) {
          add(`(?${ahead[1]}${body})`);
          i += ahead[0].length;
        } else add(`${group.open}${body})`);
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
        const m = /^(=|!|<=|<!)/.exec(pattern.slice(i + 1));
        if (!m) throw new Unsupported('\\@' + pattern[i + 1]);
        const k = last();
        top().atoms[k] = `(?${m[1]}${top().atoms[k]})`;
        i += m[1].length;
      } else if (n === '<') add(boundary((c) => `(?<!${c})(?=${c})`));
      else if (n === '>') add(boundary((c) => `(?<=${c})(?!${c})`));
      else if (n === 'z' && pattern[i + 1] === 's') { i++; top().zs = top().atoms.length; }
      else if (n === 'z' && pattern[i + 1] === 'e') { i++; top().ze = top().atoms.length; }
      else if (n === '%' && pattern[i + 1] === '^') { i++; add('(?<![\\s\\S])'); }
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
        else if (CLASSES[m]) add(`(?:${CLASSES[m]}|\\n)`);
        else throw new Unsupported('\\_' + m);
      } else if (CLASSES[n]) add(CLASSES[n]);
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
  const offsets = /^(?:(?:ms|me|hs|he|rs|re|lc)=(?:[se](?:[+-]\d+)?|\d+),?)*/.exec(text.slice(j + 1))[0];
  return { body, offsets, end: j + 1 + offsets.length };
}

const FLAGS = new Set(['contained', 'transparent', 'oneline', 'keepend', 'extend', 'excludenl', 'skipwhite',
  'skipnl', 'skipempty', 'display', 'fold', 'conceal', 'concealends']);
const LISTS = /^(contains|containedin|nextgroup|add|remove)\s*=\s*([^\s]+)/;

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

function compile(found, ignoreCase, part) {
  const pattern = { re: new RegExp(translate(found.body), ignoreCase ? 'mugi' : 'mug'), me: null };
  if (found.offsets) {
    // Nachgebaut ist nur "me=" (Ende des Treffers) bei match und beim Ende einer Region
    const m = /^me=([se])([+-]\d+)?,?$/.exec(found.offsets);
    if (!m || part === 'start' || part === 'skip') throw new Unsupported(`verschobene Grenzen ${found.offsets}`);
    pattern.me = { base: m[1], delta: Number(m[2] || 0) };
  }
  return pattern;
}

function parseItem(kind, text, ignoreCase) {
  const name = /^\S+/.exec(text)[0];
  const item = { kind, name, ignoreCase, start: [], skip: [], end: [], words: [], flags: new Set() };
  let position = name.length;
  let matchgroup = null;
  const regex = (part) => {
    const found = readPattern(text, position);
    position = found.end;
    // Wie in Vim zaehlt "excludenl" nur, wenn es vor dem Muster steht
    if ((part === 'match' || part === 'end') && !item.flags.has('excludenl') && hasEol(found.body)) item.eol = true;
    return compile(found, ignoreCase, part);
  };
  while (position < text.length) {
    const rest = text.slice(position);
    const space = /^\s+/.exec(rest);
    if (space) { position += space[0].length; continue; }
    const list = LISTS.exec(rest);
    const option = /^(matchgroup|cchar)=(\S+)/.exec(rest);
    const part = kind === 'region' && /^(start|skip|end)\s*=\s*/.exec(rest);
    const word = /^\S+/.exec(rest)[0];
    if (list) { item[list[1]] = list[2].split(','); position += list[0].length; }
    else if (option) {
      if (option[1] === 'matchgroup') matchgroup = option[2] === 'NONE' ? null : option[2];
      position += option[0].length;
    } else if (part) {
      position += part[0].length;
      item[part[1]].push({ ...regex(part[1]), group: matchgroup });
    } else if (FLAGS.has(word)) { item.flags.add(word); position += word.length; }
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
  const items = [];
  const clusters = new Map(); // Namen in Kleinbuchstaben: Vim unterscheidet Gross/Klein nicht
  const skipped = [];
  const includes = []; // Cluster der gerade offenen "syntax include"
  let ignoreCase = false;
  for (const [, command] of data.befehle) {
    const [, verb, rest = ''] = /^(\S+)\s*([\s\S]*)$/.exec(command);
    try {
      if (verb === 'case') ignoreCase = rest.startsWith('ignore');
      else if (verb === 'include') includes.push((/^@(\S+)\s/.exec(rest) || [])[1]?.toLowerCase() ?? null);
      else if (verb === 'include-end') includes.pop();
      else if (verb === 'cluster') {
        const item = parseItem('cluster', rest, ignoreCase);
        const old = clusters.get(item.name.toLowerCase()) || [];
        let members = item.contains || old;
        if (item.add) members = [...members, ...item.add];
        if (item.remove) {
          const remove = new Set(item.remove.map((m) => m.toLowerCase()));
          members = members.filter((m) => !remove.has(m.toLowerCase()));
        }
        clusters.set(item.name.toLowerCase(), members);
      } else if (['match', 'region', 'keyword'].includes(verb)) {
        const item = parseItem(verb, rest, ignoreCase);
        const cluster = includes.at(-1);
        if (cluster && !item.flags.has('contained')) {
          item.flags.add('contained');
          clusters.set(cluster, [...(clusters.get(cluster) || []), item.name]);
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
  return { items, clusters, skipped };
}

// ---- Regeln anwenden -------------------------------------------------------------

const MAXCOL = 3000; // Wie Vim ('synmaxcol'): weiter rechts wird nicht gefaerbt

function highlighter(data) {
  const { items, clusters, skipped } = load(data);
  const patterns = items.flatMap((item) => [...item.start, ...item.skip, ...item.end]);

  const listed = (list, name, seen = new Set()) => list.some((entry) => {
    if (entry.startsWith('@')) {
      const cluster = entry.slice(1).toLowerCase();
      if (seen.has(cluster)) return false;
      seen.add(cluster);
      return listed(clusters.get(cluster) || [], name, seen);
    }
    return entry.toLowerCase() === name.toLowerCase() ||
      (/[.*[\\^$]/.test(entry) && new RegExp(`^(?:${entry})$`, 'i').test(name));
  });

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
        if (item.containedin && listed(item.containedin, key.name)) return true;
        const list = key.contains;
        if (!list) return false;
        if (list[0] === 'ALL') return true;
        if (list[0] === 'ALLBUT') return !listed(list.slice(1), item.name);
        if (list[0] === 'TOP') return !item.flags.has('contained') && !listed(list.slice(1), item.name);
        if (list[0] === 'CONTAINED') return item.flags.has('contained') && !listed(list.slice(1), item.name);
        return listed(list, item.name);
      }).reverse()));
    }
    return found;
  };
  const afterwards = new Map(); // nextgroup-Liste -> Regeln
  const following = (list) => {
    let found = afterwards.get(list);
    if (!found) afterwards.set(list, found = context(items.filter((i) => listed(list, i.name)).reverse()));
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
          types.set(group, found = 'vim_' + name.replace(/[^A-Za-z0-9_-]/g, '_'));
        }
        return found;
      });
    }
    return type;
  };

  const isWord = new RegExp(`${WORD}|${EMOJI}`, 'uy');
  const afterWord = new RegExp(`(?<=${WORD}|${EMOJI})`, 'uy');
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

      // Passt das Muster bei pos? Der naechste Treffer wird gemerkt, damit nicht jede
      // Stelle neu durchsucht werden muss.
      const matches = (p, pos) => {
        if (p.from < 0 || pos < p.from || (p.index >= 0 && p.index < pos)) {
          p.re.lastIndex = pos;
          const m = p.re.exec(text);
          p.from = pos;
          p.index = m ? m.index : -1;
          if (m) {
            p.length = m[0].length;
            p.lead = 0; // Laenge des Teils vor \zs
            if (m.groups) for (const g of Object.values(m.groups)) p.lead = Math.max(p.lead, g?.length || 0);
          }
        }
        return p.index === pos;
      };
      // Ende eines Treffers, nach Verschiebung durch "me="
      const endOf = (p) => {
        if (!p.me) return p.index + p.length;
        // Vim zaehlt Zeichen, JavaScript zaehlt halbe Ersatzpaare
        let at = p.me.base === 'e' ? p.index + p.length : p.index;
        let delta = p.me.base === 'e' ? p.me.delta : p.me.delta + 1;
        for (; delta < 0; delta++) at -= /[\udc00-\udfff]/.test(text[at - 1]) ? 2 : 1;
        for (; delta > 0; delta--) at += /[\ud800-\udbff]/.test(text[at]) ? 2 : 1;
        return at;
      };

      // Findet sich hier das Ende der Region? Was "skip" erfasst, zaehlt dafuer nicht.
      const regionEnd = (frame, pos) => {
        if (frame.closing || pos < frame.content || pos < frame.noEnd) return null;
        for (const p of frame.item.skip) {
          if (!matches(p, pos)) continue;
          let to = endOf(p);
          // Reicht "skip" bis ans Zeilenende, geht die Suche in der naechsten Zeile weiter
          if (to >= text.length || text[to] === '\n') to++;
          if (to > pos) { frame.noEnd = to; return null; }
        }
        return frame.item.end.find((p) => matches(p, pos)) || null;
      };
      const startClosing = (frame, end) => {
        frame.closing = true;
        frame.end = endOf(end);
        frame.endGroup = end.group;
      };

      // "oneline": die Region beginnt nur, wenn ihr Ende in derselben Zeile liegt
      const endsOnLine = (item, pos) => {
        const probe = { item, content: pos, noEnd: pos, closing: false };
        for (let p = pos; p <= text.length; p++) {
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
        const open = (item) => stack.some((f) => f.item === item && f.from === pos);
        const keyword = keywordAt(set, pos);
        if (keyword && !open(keyword.item)) return keyword;
        for (const item of set.rules) {
          for (const start of item.start) {
            if (!matches(start, pos) || pos - start.lead < from || open(item)) continue;
            if (item.kind === 'match') {
              const end = endOf(start);
              if (end > pos) return { item, from: pos, end };
            } else {
              const content = endOf(start);
              if (!item.flags.has('oneline') || endsOnLine(item, content)) {
                return { item, from: pos, content, startGroup: start.group, noEnd: content, closing: false };
              }
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
      const close = () => {
        searchFrom = here;
        const frame = stack.pop();
        if (frame.item.nextgroup) next = { list: frame.item.nextgroup, flags: frame.item.flags };
        // Wie in Vim: Nach einer enthaltenen Regel wird das Ende einer Region von hier an neu
        // gesucht; bei "keepend" steht es fest
        const top = stack.at(-1);
        if (top && top.item.kind === 'region' && !top.closing && !top.item.flags.has('keepend')) {
          top.noEnd = here;
          // Reichte die enthaltene Regel bis ans Zeilenende, geht die Region weiter
          if (frame.item.eol && text[here] === '\n' && !stack.some((f) => f.item.flags.has('keepend'))) {
            top.noEnd = here + 1;
          }
        }
      };

      for (let pos = 0; pos < text.length;) {
        here = pos;
        // 1. "keepend": Das Ende einer solchen Region beendet auch alles, was in ihr offen
        // ist, ausser darueber liegt eine Regel mit "extend"
        let guard = 0;
        for (let i = stack.length - 1; i >= 0; i--) {
          if (stack[i].item.flags.has('extend')) { guard = i + 1; break; }
        }
        for (let i = guard; i < stack.length - 1; i++) {
          const frame = stack[i];
          if (frame.item.kind !== 'region' || !frame.item.flags.has('keepend')) continue;
          if (!frame.closing) {
            const end = regionEnd(frame, pos);
            if (end) startClosing(frame, end);
          }
          // Mit eigener Gruppe fuer das Ende hoert Enthaltenes davor auf, sonst erst dahinter
          if (frame.closing && (frame.endGroup || pos >= frame.end)) {
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
          if (top && top.item.kind === 'region' &&
              ((top.closing && top.endGroup) || (pos < top.content && top.startGroup))) break;
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
          }
          searchFrom = found.startGroup ? found.content : pos;
          stack.push(found);
          if (found.item.kind === 'keyword') break;
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
        for (let i = stack.length - 1; i >= 0 && !group; i--) {
          const f = stack[i];
          const delimiter = f.item.kind === 'region' &&
            ((pos < f.content && f.startGroup) || (f.closing && f.endGroup));
          if (delimiter) group = delimiter;
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

module.exports = { highlighter, loadData };
