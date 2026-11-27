# Known Limitations

- Terms in Clause 4 are formatted with the definition on the same line as
  the term. The LaTeX template example puts it on the next line.
- Characters that pdfLaTeX's fonts have no glyph for, such as emoji, stop the
  build until `_Specification_AuthorSettings.tex` maps them (see
  [Characters outside the Basic Multilingual Plane](13_Other_Elements.md#characters-outside-the-basic-multilingual-plane)).
- Code blocks are highlighted only for languages known to the LaTeX
  `listings` package. Code in other languages, such as FEEL, is shown without
  highlighting unless the template defines the language.
- GitHub's preview shows citations as typed, and figures without their
  captions (see [Reviewing on GitHub](15_Reviewing_on_GitHub.md#reviewing-on-github)).
