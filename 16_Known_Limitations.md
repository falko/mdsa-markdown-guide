# Known Limitations

- Terms in Clause 4 are formatted with the definition on the same line as
  the term. The LaTeX template example puts it on the next line.
- Characters that pdfLaTeX's fonts have no glyph for, such as emoji, stop the
  build until `_Specification_AuthorSettings.tex` maps them (see
  [Characters outside the Basic Multilingual Plane](13_Other_Elements.md#characters-outside-the-basic-multilingual-plane)).
- Code blocks are highlighted only for languages known to the LaTeX
  `listings` package, or defined by the specification, as FEEL is here.
- In a table, text next to an image is aligned with the middle of the image's
  first line, not centered in the row.
- Whether change bars (latexdiff) mark changes inside tables has not been tested.
- A table nested in a table cell keeps its natural width, so a narrower nested
  boxed expression leaves a jagged edge (which DMN allows). Nested tables do
  not break across pages.
- The DMN notation in a web browser (`dmn-notation.css`) lacks the double line
  between the clauses and the entries of tables with rules as columns and of
  crosstabs; GitHub shows the DMN tables with a plain grid.
- GitHub's preview shows citations as typed, and figures without their
  captions (see [Reviewing on GitHub](15_Reviewing_on_GitHub.md#reviewing-on-github)).
