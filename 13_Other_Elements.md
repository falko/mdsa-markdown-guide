# Other Elements

## Text formatting

*Emphasis*, **strong emphasis**, `inline code` and
[links](https://www.omg.org) are written as usual in Markdown. A footnote is
written like this.[^note]

[^note]: Footnotes are numbered automatically.

## Lists

1. Numbered lists
    - can be nested,
    - with bullets on the second level.
2. Bullet lists:
    - first item
    - second item

## Code listings

Fenced code blocks become code listings. With a language after the opening
backticks, the code is highlighted, here as `xml`:

```xml
<definitions xmlns="https://www.omg.org/spec/DMN/20240513/MODEL/">
  <decision id="decision1" name="Decision 1"/>
</definitions>
```

Code is formatted by pandoc, not by the LaTeX `listings` package, so it may
contain characters such as curly quotes or dashes, which are often pasted in
from a word processor or a PDF by mistake. Inline code may too:
`name = ‘Decision 1’ – draft`.

```
// copied from a PDF: “quoted” and ‘single-quoted’ text, an ellipsis …
decision ‘Approve loan’ – status: “approved”
```

## Characters outside the Basic Multilingual Plane

Some characters lie outside Unicode's Basic Multilingual Plane, such as the
horse 🐎 (U+1F40E). In UTF-16 they take two code units, but in FEEL they count
as one character, so DMN uses the horse in its string function examples. They
must appear in the PDF exactly as written, in text, in code, and in code inside
tables: `string length("🐎ab") = 3`.

```
substring("🐎ab", 2) = "ab"
string length("\U01F40Eab") = 3
```

###### Table: String functions with characters outside the Basic Multilingual Plane
| Function                | Example                          |
|-------------------------|----------------------------------|
| `substring`             | `substring("🐎ab", 2) = "ab"`    |
| `string length`         | `string length("🐎ab") = 3`      |

Write such characters directly; GitHub shows them. The PDF is built with
pdfLaTeX, whose fonts have no glyph for most of them, so the build stops with
"Unicode character 🐎 (U+1F40E) not set up for use with LaTeX" until the
specification declares how to print the character. One line in
`_Specification_AuthorSettings.tex` does it for text, code and tables alike;
this document prints the horse as an emoji image from the `twemojis` package:

```latex
\usepackage{newunicodechar}
\usepackage{twemojis}
\newunicodechar{🐎}{\twemoji{1f40e}}
```

The packages are listed in `user-pkgs.txt`, so that the build installs them.
Never map such a character to nothing to make the build pass: the examples
above would then silently become wrong.
