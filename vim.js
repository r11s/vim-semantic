'use strict';
const { execFile } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { tokenType } = require('./faerben');

const VIM_ARGS = ['-N', '-u', 'NONE', '-i', 'NONE', '-n', '-es'];

// Das Vim aus Git for Windows verschluckt Backslashes; '/' versteht jedes Vim.
const forVim = (file) => (process.platform === 'win32' ? file.replace(/\\/g, '/') : file);

// Startet Vim mit einem Skript; Daten gehen nur ueber Umgebungsvariablen.
// -V1<datei> protokolliert Vims Meldungen, damit Fehler sichtbar werden.
async function runVim(vimPath, script, env, signal) {
  const dir = await fs.promises.mkdtemp(path.join(os.tmpdir(), 'vim-log-'));
  const log = path.join(dir, 'vim.log');
  const vimEnv = { ...process.env, ...env };
  for (const key of ['VH_IN', 'VH_OUT']) {
    if (env[key]) vimEnv[key] = forVim(env[key]);
  }
  try {
    await new Promise((resolve, reject) => {
      const child = execFile(
        vimPath,
        [...VIM_ARGS, `-V1${forVim(log)}`, '-S', forVim(path.join(__dirname, 'vim', script))],
        { env: vimEnv, timeout: 20000, signal, windowsHide: true },
        (error) => (error ? reject(error) : resolve())
      );
      child.stdin.end();
    });
  } catch (error) {
    const messages = await fs.promises.readFile(log, 'utf8').catch(() => '(kein Protokoll)');
    error.message += `\nExit-Code/Signal: ${error.code ?? error.signal}` +
      `\n--- Meldungen von Vim ---\n${messages.slice(-3000)}`;
    throw error;
  } finally {
    await fs.promises.rm(dir, { recursive: true, force: true });
  }
}

async function highlight({ vimPath, text, fileName, filetype, scheme, background, signal }) {
  const dir = await fs.promises.mkdtemp(path.join(os.tmpdir(), 'vim-highlight-'));
  try {
    const input = path.join(dir, path.basename(fileName) || 'unbenannt');
    const output = path.join(dir, '.tokens');
    await fs.promises.writeFile(input, text, 'utf8');
    await runVim(vimPath, 'tokens.vim', {
      VH_IN: input, VH_OUT: output, VH_FILETYPE: filetype,
      VH_SCHEME: scheme, VH_BACKGROUND: background,
    }, signal);
    const result = await fs.promises.readFile(output, 'utf8');
    return result.split(/\r?\n/).filter(Boolean).map((row) => {
      const [line, start, length, group] = row.split('\t');
      return { line: +line, start: +start, length: +length, type: tokenType(group) };
    });
  } finally {
    await fs.promises.rm(dir, { recursive: true, force: true });
  }
}

module.exports = { runVim, highlight, tokenType };
