# DMN 1.7 in Markdown, Built with the MDSA Pipeline

[![Build specification](https://github.com/falko/mdsa-markdown-guide/actions/workflows/build.yml/badge.svg)](https://github.com/falko/mdsa-markdown-guide/actions/workflows/build.yml?query=branch%3Amain)

**Latest PDF: [DMN_1.7.pdf](https://github.com/falko/mdsa-markdown-guide/releases/latest/download/DMN_1.7.pdf)**
(built from `main` by the [workflow](https://github.com/falko/mdsa-markdown-guide/actions/workflows/build.yml?query=branch%3Amain), see the [release](https://github.com/falko/mdsa-markdown-guide/releases/tag/latest))

This repository holds the Decision Model and Notation (DMN) 1.7 Beta 1
specification, written in Markdown and built with the containerized
[MDSA](https://github.com/ObjectManagementGroup/mdsa-omg-spec) (Model Driven
Specification Authoring) pipeline. The Markdown files were converted from the Word
source of DMN 1.7 Beta 1 (`DMN_1.7_SOURCE.docx`, see
[Converting the Word source](#converting-the-word-source)), and `make` builds a PDF
with the same content as the PDF made from it with Word (`DMN_1.7_SOURCE.pdf`).

The Markdown follows the guide in [`guide/`](guide/): a small OMG specification
that explains how to write specifications in Markdown for MDSA, and serves as the
test suite of the pipeline. Its clauses are kept there for reference and are not
part of the build.

> **This is not a template.** Do not fork it or use it as the starting point for a new
> specification; it contains changes to the pipeline that are still under review.
> Start from the official template
> [ObjectManagementGroup/mdsa-omg-spec](https://github.com/ObjectManagementGroup/mdsa-omg-spec)
> or the containerized
> [jasonmccsmith/containerized-spec](https://github.com/jasonmccsmith/containerized-spec),
> and use this repository to look up how things are done.

## What the guide shows

| Feature | Markdown syntax | Example in |
|---|---|---|
| One file per clause from Clause 7 on, included automatically | `07_Title.md`, `08_Title.md`, … | [`07_Markdown_in_the_MDSA_Pipeline.md`](guide/07_Markdown_in_the_MDSA_Pipeline.md) to [`16_Known_Limitations.md`](guide/16_Known_Limitations.md) |
| Numbered clauses and subclauses | `# Title` (never type numbers) | [`08_Sections.md`](guide/08_Sections.md) |
| Unnumbered headings | `## Title {-}` | [`08_Sections.md`](guide/08_Sections.md) |
| SVG figures with captions | `![Caption](Images/file.svg)` | [`07_Markdown_in_the_MDSA_Pipeline.md`](guide/07_Markdown_in_the_MDSA_Pipeline.md), [`09_Figures.md`](guide/09_Figures.md), [`guide/Images/`](guide/Images/) |
| Captioned tables, long tables | `###### Table: Caption` before the table | [`05_Symbols.md`](guide/05_Symbols.md), [`10_Tables.md`](guide/10_Tables.md) |
| Links to sections, also between files: links on GitHub, section numbers in the PDF | `[Title](08_Sections.md#anchor)`, `[Title](#anchor)` | [`11_Cross-references.md`](guide/11_Cross-references.md), all Markdown files |
| Links to figures and tables: links on GitHub, numbers in the PDF | `[Caption](Images/file.svg)`, `[Caption](10_Tables.md#table-caption)` | [`11_Cross-references.md`](guide/11_Cross-references.md) |
| Citations, normative and non-normative | `[@DMN16]` | [`12_Citations.md`](guide/12_Citations.md), [`01_Scope.md`](guide/01_Scope.md), [`specification.bib`](specification.bib) |
| Terms and definitions | definition lists | [`04_Terms.md`](guide/04_Terms.md) |
| Lists, footnotes, code | standard Markdown | [`13_Other_Elements.md`](guide/13_Other_Elements.md) |
| Notes | `> [!NOTE]` | [`15_Reviewing_on_GitHub.md`](guide/15_Reviewing_on_GitHub.md) |
| Annexes | `# Title` in `A_Annexes.md` | [`A_Annexes.md`](guide/A_Annexes.md) |
| Table of contents, lists of figures and tables | generated | — |

## How it works

Each clause of an MDSA specification is a file named with a two-digit clause number,
such as `01_Scope.tex`. A Markdown file with the same name (`01_Scope.md`) replaces
it. The build converts each Markdown
file to LaTeX with [Pandoc](https://pandoc.org/), resolves cross-references with
[pandoc-crossref](https://lierdakil.github.io/pandoc-crossref/), and builds the PDF
with the OMG LaTeX templates from
[mdsa-omg-core](https://github.com/ObjectManagementGroup/mdsa-omg-core). Everything
runs in a Docker container, so no local LaTeX or Pandoc installation is needed.

DMN keeps its own clause structure, which differs from the OMG template's: it has no
clauses for terms and symbols, and its references are Clause 3. The repository
therefore has its own `Specification_Template.tex`, which replaces the template of
`mdsa-omg-core` (a local file replaces the core file of the same name). It includes:

- the notices and the preface of DMN (`00_Notices.md`, `00_Preface.md`), after
  the cover page and copyrights (`\maketitle` and `\copyrights` in
  `_Specification_AuthorSettings.tex`) and before the table of contents;
- Clauses 1, 2 and 4 (`01_Scope.md`, `02_Conformance.md`,
  `04_Additional_information.md`) and Clause 3, References, from
  `specification.bib`;
- the clauses listed in `07+_Technical_Content.tex`, Clauses 5 to 14
  (`05_Introduction_to_DMN.md` … `14_DMN_Diagram_Interchange_DMN_DI.md`), and the
  annexes (`A_Annexes.md`).

Each clause file is named after its two-digit clause number and title, and starts
with one `#` heading, its title. In every Markdown file, `#` is a clause and `##` a
subclause.

`omgLaTeX.yaml` replaces the Pandoc settings of `mdsa-omg-core` to put table
captions above the tables, and `_Specification_AuthorSettings.tex` sets DMN's
numbering (Figure 6-1, Table 1 to 111, headings numbered to the sixth level),
cover page, footers and figure placement.

## Made for GitHub's preview

Changes are mostly reviewed in GitHub's preview of the Markdown files, and with
a public source, anyone who knows Markdown should be able to fix a typo or
propose a change with a pull request. So the pipeline reads standard Markdown
the way GitHub does:

- Nothing carries an identifier. Sections, figures and tables are referenced with
  ordinary links, with the title or caption as link text:
  - a section: a link to its heading, `[Figures](09_Figures.md#figures)`
  - a figure: a link to its image, `[Build pipeline](Images/build-pipeline.svg)`
  - a table: a link to its caption, which is a heading `###### Table: Caption`
    directly above the table, `[Abbreviations](05_Symbols.md#table-abbreviations)`

  GitHub shows and follows the links; the PDF shows the number instead ("Clause 9",
  "10.1", "Annex A", "Figure 7.1", "Table 5.1"), generated by the filter
  `crossref-links.lua` of `mdsa-omg-core`. The build warns if a link text is not
  the title or caption of its target.
- Lists and headings directly after a line of text, without a blank line, are
  lists and headings in the PDF too, as on GitHub. Before, they became plain text.
- Bare web addresses become links, and GitHub's `> [!NOTE]` blocks are supported.

[Clause 15](15_Reviewing_on_GitHub.md#reviewing-on-github) lists what GitHub shows
as typed (citations) and what to avoid because GitHub and the PDF show it
differently, such as HTML or `H~2~O`.

## Building locally

Requirements: Docker, make and git.

```bash
make
```

This builds the Docker image (the first time takes several minutes) and the PDF,
`DMN_1.7.pdf`. `make check` also checks the PDF for undefined references and
citations and for Markdown references that Pandoc did not process, and fails if it
finds any.

The Makefile uses the Pandoc toolchain (`make pandoc ...` still works) and, until
the Markdown pipeline fixes are merged into `mdsa-omg-core`, the branch of
`mdsa-omg-core` that contains them: the first build clones it into
`.ci/mdsa-omg-core`. Use another checkout with `make core=../mdsa-omg-core`, or the
core of the Docker image with `make core=`.

The `latest-ubuntu` Pandoc image may print "pandoc-crossref was compiled with pandoc
… but is being run through …" for each Markdown file. This warning can be ignored;
`make check` verifies the result.

## Converting the Word source

The Markdown files and images were made from the Word source of DMN 1.7 Beta 1 with
`tools/convert.sh`, which needs pandoc 3, python3 and poppler (`pdftotext`,
`pdftoppm`, `pdftocairo`):

```bash
tools/convert.sh DMN_1.7_SOURCE.docx DMN_1.7_SOURCE.pdf
```

Neither file is in the repository. The conversion overwrites the clause files and
`Images/`, and writes its notes (figures, tables, references it resolved or could
not resolve) to `convert.log`. It writes the Markdown as the guide asks for:

- Each clause of DMN becomes a file named after its number and title
  (`01_Scope.md` … `14_DMN_Diagram_Interchange_DMN_DI.md`, listed from Clause 5
  on in `07+_Technical_Content.tex`), the annexes `A_Annexes.md`, the notices and
  the preface `00_Notices.md` and `00_Preface.md`, and the references of Clause 3
  the entries of `specification.bib`.
- References to clauses, figures and tables, linked in Word or written as text
  ("see clause 10.3.4", "Figure 8-5"), become links to the heading, image or
  table caption, so that the PDF shows the generated numbers.
- Tables become pipe tables with a `###### Table:` caption. Content that a pipe
  table cannot hold is put on one line: paragraphs and line breaks joined, list
  items with bullets, merged cells split.
- Images become SVG files: SVG images are copied, PNG and JPEG images embedded
  in an SVG file. Figures that Word draws with tables or text boxes (boxed
  expressions) are cut from the PDF as vector graphics.
- Sub- and superscripts become Unicode characters (e₁, 10⁻¹), also those that
  Word only sets in a smaller font (`tools/subscripts.py`), lettered lists
  paragraphs starting with the letter, the FEEL and S-FEEL grammars code blocks,
  and headings that are unnumbered in Word `{-}` headings.

### Differences from the Word PDF

The PDF has the structure, content and page layout of the PDF made with Word:
A4 pages with the same margins, line and paragraph spacing, footers, cover page,
copyrights and notices, table of contents, preface, the same clauses, headings and
numbers (Figure 6-1, Table 1 to Table 111), table captions above the tables, tables
in a sans-serif font, a page "This page intentionally left blank." before each
clause from Clause 5 on and before the annexes, and the same text. Checked
against `DMN_1.7_SOURCE.pdf`: all 271 numbered headings and all figure and table
captions match, and the clauses start within a few pages of where they start
there. Differences:

- LaTeX breaks lines and pages differently from Word. The PDF has 258 pages
  instead of 270, most of the difference in the glossary (Annex B), whose table
  rows Word makes much higher than their text.
- Tables have the rules of the template instead of a grid, and references are
  formatted by biblatex.
- The text of the boxed expressions cut from the Word PDF (Figures 10-4 to 10-11,
  10-13 to 10-15 and 10-28) is part of the image.

## Continuous build

The workflow [`.github/workflows/build.yml`](.github/workflows/build.yml) runs the
same `make check` on every push and pull request, using this repository's own
`Dockerfile` and `Makefile` (no separate CI image). A pull request that breaks a
feature fails the check.

- **Docker layer cache:** the image layers are kept in the GitHub Actions cache. The
  Makefile passes the latest `mdsa-omg-core` and `mdsa-tools` commits as build
  arguments, so cached layers are reused until one of them, or the `Dockerfile`,
  changes. The cache options are handed to `docker build` with the Makefile option
  `docker_build_opts`.
- **PDF:** every run keeps the PDF as the artifact `specification-pdf`. Builds of
  `main` also replace the release [`latest`](https://github.com/falko/mdsa-markdown-guide/releases/tag/latest),
  so the PDF has the stable download link at the top of this page.
- **Annotations:** in GitHub Actions, the build reports its warnings (e.g. a link
  text that is not the heading title) and `make check` errors as annotations,
  which a pull request shows on the changed lines. The Makefile passes
  `GITHUB_ACTIONS` into the container for this.

## Status of the pipeline changes

This repository needs changes to the MDSA pipeline that are proposed upstream:

- [Pull requests to mdsa-omg-core](https://github.com/ObjectManagementGroup/mdsa-omg-core/pulls?q=is%3Apr+author%3Afalko):
  fixes for SVG images, tables, annexes and local overrides, cross-references and
  citations, a preamble generated from Pandoc's own template, lists of figures and
  tables, `make check`, and reading Markdown the way GitHub does (heading anchors,
  links to headings, lists and headings without blank lines); in a second step, zero-padded clause file names and the
  automatic inclusion of the clause files from Clause 7 on (older specifications with
  unpadded names keep working). Also: typographic characters in code (curly quotes,
  dashes, copied from Word or PDF) reported with file and line, annotations in
  GitHub Actions, all tables as tabularray tables in the OMG style (full grid),
  HTML tables with Markdown in the cells, automatically numbered grammar rules
  with references, and a hook for a specification's own filter
  (`specification.lua`).
- [Pull requests to mdsa-omg-spec](https://github.com/ObjectManagementGroup/mdsa-omg-spec/pulls?q=is%3Apr+author%3Afalko):
  `mdsa-omg-core` submodule from the OMG repository; zero-padded clause file names.
- To follow for `containerized-spec` (already applied here in `Dockerfile` and
  `Makefile`): zero-padded clause file names, Inkscape and the `catchfile` LaTeX
  package for SVG images, `tlmgr update --self`, picking up new core versions without
  `make forcebuild`, the LaTeX packages `tabularray`, `ninecolors` and `varwidth` for
  tables, the `check`, `core=`, `pandoc_tag=`, `texlive_repository=`
  and `docker_build_opts=` options, and passing `GITHUB_ACTIONS` into the container
  for annotations.

## Known limitations

- Characters without a glyph in pdfLaTeX's fonts, such as the subscripts and
  mathematical symbols of DMN, need a mapping in
  `_Specification_AuthorSettings.tex`, one line for text and, in code, one for
  `listings` (see Clause 13 of the guide).
- Visual aspects (layout, figure rendering, page breaks in tables) are not checked
  automatically; use the checklist in Annex A of the guide.

## Files

| File | Content |
|---|---|
| `00_Notices.md`, `00_Preface.md` | Notices and preface |
| `01_Scope.md`, `02_Conformance.md`, `04_Additional_information.md` | Clauses 1, 2 and 4 |
| `05_Introduction_to_DMN.md` … `14_DMN_Diagram_Interchange_DMN_DI.md` | Clauses 5 to 14, one Markdown file each, listed in `07+_Technical_Content.tex` |
| `A_Annexes.md` | Annexes A and B |
| `specification.bib` | References of DMN (Clause 3) |
| `Images/` | SVG figures |
| `Specification_Template.tex`, `omgLaTeX.yaml` | DMN's versions of the template and Pandoc settings of `mdsa-omg-core` |
| `_Specification_Setup.tex`, `_Specification_AuthorSettings.tex` | Specification metadata and author settings |
| `tools/` | Conversion of the Word source: `convert.sh`, `docx2md.lua`, `images.py`, `subscripts.py`, `unnumbered.py` |
| `guide/` | The guide to writing OMG specifications in Markdown, with its own figure (not built) |
| `Dockerfile`, `Makefile`, `Makefile.mdsa`, `user-pkgs.txt` | Containerized build, from `containerized-spec` with the changes listed above |
