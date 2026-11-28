# vim-semantic (VimSem)

The color schemes of Vim in the editor of VS Code and VSCodium, looking as they do in Vim.
**Vim does not need to be installed:** the extension applies Vim's syntax rules itself and shows
the result as semantic tokens. It contains 34 themes "VimSem ..." for the color schemes of
Vim 9.2.

It is only about the display in the editor, not about the behavior of Vim.

**Coloring without Vim is new and still an experiment.**

## Languages

These Vim file types are colored:

abap, ada, arduino, asm, autohotkey, awk, basic, bib, c, clojure, cobol, cpp, cs, css, cuda, d,
dart, diff, dockerfile, dosbatch, dosini, elm, erlang, forth, gdscript, glsl, go, groovy,
haskell, html, java, javascript, javascriptreact, json, jsonc, julia, kotlin, less, lisp, lua,
make, markdown, matlab, mojo, nix, nu, objc, ocaml, pascal, perl, php, plaintex, progress, prolog, ps1,
pyrex, python, r, racket, raku, ruby, rust, sas, scala, scheme, scilab, scss, sh, sml,
solidity, sql, st, stata, swift, systemverilog, tcl, tex, toml, typescript, typescriptreact, uc,
vb, verilog, vhdl, xml, yaml, zig

Everything else is **not colored**, for example:

- Vim script and Fortran
- Objective-C++ (`.mm`, and `.h` files in which a line starts with `@interface`, `@class` or
  `@end`)
- zsh, csh, tcsh, Vue, Svelte
- ConTeXt and BibTeX style files (`.bst`)
- what is a file type of its own in Vim: SVG, XSD, XSLT, DocBook, XBL and patches from
  `git format-patch`

Which rules apply is decided as in Vim 9.2 by the file name (`dateitypen.json`) and, for
ambiguous extensions such as `.h .m .pl .v .bas .p`, by the content (`erkennen.js`). Files
without a matching name are recognized by a first line `#!...`, unsaved files by the language
selected in VS Code. On Windows and macOS, upper and lower case do not matter.

As in Vim, there are also several rule sets for makefiles (GNU, BSD, Microsoft) and diff
("unified" and other formats).

As in Vim, TeX is LaTeX or Plain TeX depending on the content. Style files (`.sty`, `.cls`,
`.clo`, `.ltx`) and `.dtx` have rule sets of their own.

For shell scripts there are three rule sets, as in Vim: bash, Korn shell and POSIX. The first
line decides, otherwise the file name (`.bashrc`, `*.bash`, `*.ksh` ...). `#!/bin/sh` and files
without any indication count as POSIX shell, as in Vim on Windows.

## How accurate?

Compared with Vim 9.2 (patches 1-858) on Linux, without custom settings:

- 96 test files from `test/` in all 34 themes: no differences.
- 1526 TeX files of the system (LaTeX, Plain TeX, style files, `.dtx`): no differences.
- 545 further files of the system of the types diff, dockerfile, dosini, jsonc, make, scss,
  toml, tsx, xml and others: no visible differences.
- a sample of 438 C and C++ files and headers without differences.
- 322 further files in 39 languages (Vim's syntax tests and files of the system): 320 identical,
  the other two are HTML templates.

More in [MESSUNGEN.md](MESSUNGEN.md) (in German). **One test file per language does not check
every language construct.** Differences are to be expected with other code.

Known differences:

- COBOL: lines that go beyond column 72 can look different. Vim's rules do not know the free
  format; as in gVim, large parts of it appear as errors.
- The variants of the Korn shell (ksh88, ksh93, mksh) are all colored the same way.
- Templates in HTML (Angular, Django) are colored as HTML only.
- After a line with more than 3000 characters, the following line can look different.

## Installation

Needs Node.js version 20 or later, and internet the first time (downloads `@vscode/vsce`).

    bash werkzeuge/vsix.sh                                   # builds vim-semantic-<version>.vsix
    code --install-extension vim-semantic-1.0.1.vsix --force
    codium --install-extension vim-semantic-1.0.1.vsix --force      # for VSCodium

Then restart VS Code or VSCodium and choose a "VimSem ..." color theme.

Remove: `code --uninstall-extension r11s.vim-semantic` (VSCodium: `codium` instead of `code`)

## Bringing the editor even closer to Vim

VimSem does not change any settings of VS Code or VSCodium. If you like, add to your
`settings.json` (command "Open User Settings (JSON)"):

```json
"editor.bracketPairColorization.enabled": false,
"editor.occurrencesHighlight": "off",
"editor.selectionHighlight": false,
"editor.renderLineHighlight": "none"
```

| Setting | Effect |
|---|---|
| `editor.bracketPairColorization.enabled` | do not color brackets by depth (recommended) |
| `editor.occurrencesHighlight` | do not highlight the word under the cursor everywhere |
| `editor.selectionHighlight` | do not highlight places that match the selected text |
| `editor.renderLineHighlight` | no bar on the current line |

These settings apply to all color themes.

If you use `set cursorline` in Vim, leave out the last line: the themes already have the color of
`CursorLine`. You can change it with `editor.lineHighlightBackground` in
`workbench.colorCustomizations`.

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `vimsem.backgroundGroups` | `["Todo", "Error", "Constant"]` | groups with a background |
| `vimsem.logFile` | `false` | log to `protokoll.txt` in the extension folder |

Troubleshooting: "Output" view, channel "VimSem".

## Requesting a new language

Is a language missing, or is one not colored as in Vim? Then please open an
[issue](https://github.com/r11s/vim-semantic/issues) with the name of the language, the file
extension and, if possible, a small example. It may be included in one of the next releases.
Requirement: Vim has a syntax for the language.

## Limitations

- Backgrounds only for the configured groups. Semantic tokens have no background, so the
  extension uses decorations for it.
- Where Vim has no usable color (for example for the selection in elflord), the color of
  VS Code applies. VS Code cannot show bold line numbers.
- The whole file is recalculated on every change. For 5000 lines this usually takes less than
  0.5 seconds, for a few languages (JSON, Nushell) a good 1 second (measured on Linux).
- Syntax is always calculated from the start of the file (like `syntax sync fromstart`).
- Without vimrc and plugins.
- Other semantic token providers (for TypeScript, for example) can take precedence.

## Development

Vim 9 is only needed to generate themes or data, or to measure.

Test window without installing:

    code --extensionDevelopmentPath=/path/to/vim-semantic

Generate themes (uses your Vim; `VIM_PATH` sets another one). The colors of the user interface
are calculated by `oberflaeche.js` from Vim's groups:

    node generate.js elflord dark       # add or renew one theme
    bash werkzeuge/themes.sh            # regenerate all existing ones

Measure:

    node measure.js blue                # for light and dark: node measure.js <name> light|dark

Compares color, style and background per character (without whitespace): expected values from
`vim/reference.vim` (Vim), actual values from the extension's colorizer (`faerben.js`) and the
theme file. Differences are written to `messung/<name>-<light|dark>.txt`. This is calculated: what
VS Code actually displays is not checked.

| Folder | Content |
|---|---|
| `themes/` | the generated VS Code themes |
| `vim/` | Vim scripts |
| `test/` | test programs, see [test/README.md](test/README.md) |
| `syntaxdaten/` | Vim's coloring rules per language, see [syntaxdaten/README.md](syntaxdaten/README.md) |
| `schemata/` | where a color scheme assigns a group differently |
| `werkzeuge/` | scripts for building, generating and checking |

Compare with Vim and generate data:

    node werkzeuge/ohne-vim-messen.js auto file...    # with SCHEMA=blue BG=dark for another one
    node werkzeuge/schema-gruppen.js cpp              # regenerate schemata/cpp.json
    node werkzeuge/schema-gruppen.js sh test/08_shell.sh   # sh needs a sample file
    node werkzeuge/schema-gruppen.js sh-posix file          # file with "#!/bin/sh"; sh-ksh: "#!/bin/ksh"
    node werkzeuge/schema-gruppen.js make-bsd file          # likewise make-microsoft, diff-context
    node werkzeuge/schema-gruppen.js tex-sty file.sty       # likewise tex-dtx with a ".dtx"
    node werkzeuge/dateitypen.js                      # dateitypen.json (needs VIMRUNTIME)

Short commands: [SPICKZETTEL.md](SPICKZETTEL.md) (in German).

## License

VimSem is under the Vim license, see [LICENSE](LICENSE).

Themes, syntax data and file type detection are derived from files of
[Vim](https://github.com/vim/vim) and have been changed in the process. The notices of these
files, including those with a license of their own, are in [LIZENZEN.md](LIZENZEN.md).
Regenerate: `werkzeuge/lizenzen.js`.

Contact (section II 2a of the Vim license): <https://github.com/r11s/vim-semantic/issues>
