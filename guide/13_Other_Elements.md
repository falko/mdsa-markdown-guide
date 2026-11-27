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

Fenced code blocks become code listings, formatted with the LaTeX `listings`
package as in the OMG LaTeX templates. With a language known to `listings`
after the opening backticks, the code is highlighted, here as `xml`:

```xml
<definitions xmlns="https://www.omg.org/spec/DMN/20240513/MODEL/">
  <decision id="decision1" name="Decision 1"/>
</definitions>
```

Code, in code blocks and in inline code, may contain only ASCII characters.
Word processors replace straight quotes with curly ones, `--` with a dash and
`->` with an arrow as you type, and copying code from Word or PDF documents
brings these characters along. In code they are errors. The build reports each
one with its file and line, and the character to write instead, e.g.
"code contains ’ (U+2019) ...; write ' instead", and then stops. Curly quotes
and dashes in normal text are fine.

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
pdfLaTeX, whose fonts have no glyph for most of them. Until the specification
declares how to print such a character, the build stops with "Unicode character
🐎 (U+1F40E) not set up for use with LaTeX" in text and "Invalid UTF-8 byte
sequence" in code. Declare it in `_Specification_AuthorSettings.tex`, once for
text and once for code; this document prints the horse as an emoji image from
the `twemojis` package:

```latex
\usepackage{newunicodechar}
\usepackage{twemojis}
\newunicodechar{🐎}{\twemoji{1f40e}}           % text
\lstset{literate={🐎}{{\twemoji{1f40e}}}1}     % code
```

The packages are listed in `user-pkgs.txt`, so that the build installs them.
Never map such a character to nothing to make the build pass: the examples
above would then silently become wrong.
