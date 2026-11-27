# VimSem

The color schemes of Vim 9.2 in the editor of VS Code and VSCodium. A file should look the way
gVim shows it with its default settings (no vimrc, no plugins).

**Vim does not need to be installed.** VimSem applies Vim's syntax rules itself.

## Choose a theme

Run *Preferences: Color Theme* and pick one of the 34 themes named "VimSem ...":

blue, catppuccin*, darkblue, default, delek, desert, elflord, evening, habamax, industry,
koehler, lunaperche*, morning, murphy, novum*, pablo, peachpuff, quiet*, retrobox*, ron,
shine, slate, sorbet, torte, unokai, wildcharm*, zaibatsu, zellner

\* in light and dark

## Requirement: semantic highlighting

VimSem colors code with semantic highlighting. If your `settings.json` contains this line,
**remove it**, otherwise the syntax colors do not appear:

```json
"editor.semanticHighlighting.enabled": false
```

The extension "Vim Colorschemes" recommends this setting. If you added it for that extension,
remove it when you switch to VimSem.

## Languages

ABAP, Ada, Arduino, Assembly, AutoHotkey, AWK, BASIC, Batch, C, C#, C++, Clojure, COBOL, CSS,
CUDA, Cython, D, Dart, Elm, Erlang, Forth, GDScript, GLSL, Go, Groovy, Haskell, HTML, Java,
JavaScript, JSON, Julia, Kotlin, Lisp, Lua, Markdown, MATLAB, Mojo, Nix, Nushell,
Objective-C, OCaml, Pascal, Perl, PHP, PowerShell, Progress, Prolog, Python, R, Racket, Raku,
Ruby, Rust, SAS, Scala, Scheme, Scilab, Shell (sh, bash, ksh), Smalltalk, Solidity, SQL,
Standard ML, Stata, Swift, SystemVerilog, Tcl, TypeScript, UnrealScript, Verilog, VHDL,
Visual Basic, YAML, Zig

No language extensions are needed for the colors. As in Vim, the file name and sometimes the
content decide which rules apply.

**Other files are shown without syntax colors** while a VimSem theme is active, for example
JSX and TSX, XML, SCSS, Less, TOML, INI, Makefile, Dockerfile, Diff, Vue, Svelte, Fortran,
Vim script, zsh, csh and JSON with comments (including `tsconfig.json` and VS Code's user
`settings.json`).

## Only the editor

VimSem themes set the colors of the code, the text and the editor background. Side bar, tabs,
status bar and the rest of VS Code keep the standard light or dark colors.

## Recommended settings

VimSem does not change any of your settings. To get closer to Vim, you can add these to your
`settings.json`:

```json
"editor.bracketPairColorization.enabled": false,
"editor.occurrencesHighlight": "off",
"editor.selectionHighlight": false,
"editor.renderLineHighlight": "none"
```

They stop VS Code from coloring brackets by depth, marking other occurrences of the word under
the cursor or of the selected text, and highlighting the current line. They apply to all
themes.

If you use `set cursorline` in Vim, keep the line highlight and give it Vim's color for each
theme instead:

```json
"editor.renderLineHighlight": "line",
"workbench.colorCustomizations": {
  "[VimSem elflord]": {
    "editor.lineHighlightBackground": "#333333",
    "editor.lineHighlightBorder": "#00000000"
  }
}
```

`#333333` is only an example. gVim shows the color of the current scheme with
`:echo synIDattr(hlID('CursorLine'), 'bg#')`.

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `vimsem.backgroundGroups` | `["Todo", "Error", "Constant"]` | Vim highlight groups whose background color is shown |
| `vimsem.logFile` | `false` | Also write the log to `protokoll.txt` in the extension folder |

## Limitations

- Cursor line, line numbers, selection and search matches use the colors of VS Code.
- After each change the whole file is colored again, so very large files react slower.
- Another extension that provides semantic highlighting for the same language may take
  precedence.
- HTML templates (for example Django or Angular) are colored as plain HTML.
- COBOL is colored for the fixed format only, as in Vim.
- Differences from Vim are possible. Please report them.

## Feedback

Found a difference from Vim, or missing a language? Please open an
[issue](https://github.com/r11s/vim-semantic/issues) with the language, the theme and a short
example. A language can only be added if Vim has syntax highlighting for it.

## License

VimSem is distributed under the Vim license, see [LICENSE](LICENSE). Themes, syntax data and
file type detection are derived from files of [Vim](https://github.com/vim/vim) and have been
modified. Details for each file are in [LIZENZEN.md](LIZENZEN.md) (in German).

## Development

See [README_DEV.md](README_DEV.md) (in German).
