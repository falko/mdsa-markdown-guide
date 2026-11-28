# DMN 1.7 in Markdown, Built with the MDSA Pipeline

[![Build specification](https://github.com/falko/mdsa-markdown-guide/actions/workflows/build.yml/badge.svg?branch=dmn-1.7)](https://github.com/falko/mdsa-markdown-guide/actions/workflows/build.yml?query=branch%3Admn-1.7)

This branch holds the Decision Model and Notation (DMN) 1.7 Beta 1
specification, written in Markdown and built with the containerized
[MDSA](https://github.com/ObjectManagementGroup/mdsa-omg-spec) (Model Driven
Specification Authoring) pipeline. It was converted from the Word source of DMN
1.7 Beta 1 (see [Converting the Word source](#converting-the-word-source)) and
then edited so that reviewers can read and change everything in GitHub's
preview: decision tables and boxed expressions are tables, not images, and FEEL
is code. The PDF of each build is attached to its run of the
[workflow](https://github.com/falko/mdsa-markdown-guide/actions/workflows/build.yml?query=branch%3Admn-1.7).

The Markdown follows the guide in [`guide/`](guide/): a small OMG specification
that explains how to write specifications in Markdown for MDSA, and serves as the
test suite of the pipeline. Its clauses are kept there for reference and are not
part of the build. This branch will move to a repository of its own.

## Building

Requirements: Docker, make and git.

```bash
make check
```

This builds the Docker image (the first time takes several minutes) and the PDF,
`DMN_1.7.pdf`, and checks it for undefined references and citations and for
Markdown references that Pandoc did not process.

Until the Markdown pipeline changes are merged into `mdsa-omg-core`, the build
uses the branch of `mdsa-omg-core` that contains them: it is cloned into
`.ci/mdsa-omg-core` and updated on each build. Use another checkout with
`make core=../mdsa-omg-core check`. The "pandoc-crossref was compiled with
pandoc ..." warnings can be ignored.

## How DMN is written

Everything the guide describes, and in addition:

- **Decision tables and boxed expressions** are HTML tables in the DMN notation,
  drawn by `specification.lua` (the hook of `mdsa-omg-core`) as DMN 8.2 and
  10.2.1 describe them; see "Specification-specific table styles" in
  [`guide/10_Tables.md`](guide/10_Tables.md). DMN also uses cells of class
  `optional` (inverse, in the schematic layouts), `highlight` and `invalid`
  (in illustrations), and rows of class `double-line` (between list items).
  They have ordinary table captions, so they are numbered as tables.
- **FEEL** in the text is inline code: `specification.lua` highlights all inline
  code as FEEL, unless it starts with `<` (XML). In HTML table cells, write
  `<code>...</code>`. FEEL in decision tables and boxed expressions stays plain
  text. Code blocks of FEEL are ```` ```feel ````, XML ```` ```xml ````.
- **Grammars**: every rule and alternative has an anchor, `rule-<name>` and
  `rule-<name>-i`, `-ii`, ... (S-FEEL rules `rule-s-feel-<name>`); references are
  links to them, and the "Grammar Rule" columns are links whose text is the rule
  number, so the PDF prints the generated numbers.
- **Characters** without a glyph in pdfLaTeX's fonts, such as the subscripts and
  mathematical symbols of DMN, are mapped in `_Specification_AuthorSettings.tex`.
- **Structure**: `Specification_Template.tex` keeps DMN's structure (Clauses 1 to
  14 without Terms and Symbols clauses, the page "ANNEXES"), DMN's numbering
  (Figure 6-1, tables numbered continuously, six heading levels), the cover,
  notices and preface, and captions above tables.

## Converting the Word source

The Markdown files and images were made from the Word source of DMN 1.7 Beta 1 with
`tools/convert.sh`, which needs pandoc 3, python3 and poppler (`pdftotext`,
`pdftoppm`, `pdftocairo`):

```bash
tools/convert.sh DMN_1.7_SOURCE.docx DMN_1.7_SOURCE.pdf
```

Neither file is in the repository. The conversion overwrites the clause files and
`Images/`, and writes its notes (figures, tables, references it resolved or could
not resolve) to `convert.log`. It writes the Markdown as the guide asks for (the Markdown was then edited
further, see [How DMN is written](#how-dmn-is-written); a new conversion would
lose those edits):

- Each clause of DMN becomes a file named after its number and title
  (`01_Scope.md` … `14_DMN_Diagram_Interchange_DMN_DI.md`, listed from Clause 5
  on in `07+_Technical_Content.tex`), the annexes `A_Annexes.md`, the notices and
  the preface `00_Notices.md` and `00_Preface.md`, and the references of Clause 3
  the entries of `specification.bib`.
- References to clauses, figures and tables, linked in Word or written as text
  ("see clause 10.3.4", "Figure 8-5"), become links to the heading, image or
  table caption, so that the PDF shows the generated numbers.
- Tables get a `###### Table:` caption heading and are written as the guide
  asks for (`guide/10_Tables.md`): pipe tables, with `<br>` for line breaks;
  tables with merged cells, several paragraphs, lists or code in a cell, or
  whose first row is not a heading row (Word repeats only real heading rows),
  as HTML tables with Markdown in the cells.
- Images become SVG files: SVG images are copied, PNG and JPEG images embedded
  in an SVG file.
- The glossary (Annex B) becomes a definition list, as terms are written in
  the guide.
- Images that Word groups next to a figure (Figure 12-56) are combined into
  the figure's SVG file.
- The FEEL and S-FEEL grammars become numbered lists with their alternatives
  as nested lists; references such as "grammar rule 33" or "rule 7.b" become
  links to them (`guide/13_Other_Elements.md`).
- FEEL code is marked as such (```` ```feel ````), and all code is in fenced
  code blocks.
- Sub- and superscripts become Unicode characters (e₁, 10⁻¹), also those that
  Word only sets in a smaller font (`tools/subscripts.py`), and lettered lists
  paragraphs starting with the letter.

### Comparing with the Word PDF page by page

The Markdown as converted from Word had the pages of the Word PDF
(`DMN_1.7_SOURCE.pdf`): the build started pages where the Word PDF starts them,
using the first words of each Word page (`tools/dmn-pages.txt`, written by
`tools/pages.py`), and started each clause on its Word page. Both had 270 pages,
the same blank pages, numbered headings and captions, and on 216 of the 267 pages
with text the first words were on the same page.

This made the conversion easy to check page by page, but it fits only that
Markdown: after any edit, the pages no longer match. So it is off. To use it on
the Markdown as converted, uncomment the lines at the end of `Makefile.mdsa` and
add `\dmnwordpagestrue` to `_Specification_AuthorSettings.tex`.

## Known limitations

- Figures that are diagrams (DRDs, class diagrams, the decision table examples
  with callouts) stay images.
- A table nested in a cell keeps its natural width; where that is too wide, the
  boxed expression uses merged cells instead.
- The top line of a boxed expression is not drawn over a gap column
  ("Horizontal context"), a quirk of tabularray.
- Visual aspects (layout, figure rendering, page breaks in tables) are not checked
  automatically; use the checklist in Annex A of the guide.

## Files

| File | Content |
|---|---|
| `00_Notices.md`, `00_Preface.md` | Notices and preface |
| `01_Scope.md`, `02_Conformance.md`, `04_Additional_information.md` | Clauses 1, 2 and 4 |
| `05_Introduction_to_DMN.md` … `14_DMN_Diagram_Interchange_DMN_DI.md` | Clauses 5 to 14, one Markdown file each, listed in `07+_Technical_Content.tex` |
| `.github/workflows/build.yml` | Builds the PDF for each push and pull request |
| `A_Annexes.md` | Annexes A and B |
| `specification.bib` | References of DMN (Clause 3) |
| `Images/` | SVG figures (diagrams) |
| `Specification_Template.tex` | DMN's version of the template of `mdsa-omg-core` |
| `specification.lua` | DMN's own Pandoc filter: the notation of decision tables and boxed expressions, FEEL code, the table style, and (off) the pages of the Word PDF |
| `_Specification_Setup.tex`, `_Specification_AuthorSettings.tex` | Specification metadata and author settings |
| `tools/` | Conversion of the Word source (`convert.sh`, `docx2md.lua`, `images.py`, `subscripts.py`, `unnumbered.py`), and the pages of the Word PDF (`pages.py` writes `dmn-pages.txt`, for the page-by-page comparison) |
| `guide/` | The guide to writing OMG specifications in Markdown, with its own figure (not built) |
| `Dockerfile`, `Makefile`, `Makefile.mdsa`, `user-pkgs.txt` | Containerized build, from `containerized-spec` with the changes listed above |
