# Writing OMG Specifications in Markdown: Guide and Test Suite

[![Build specification](https://github.com/falko/mdsa-markdown-guide/actions/workflows/build.yml/badge.svg)](https://github.com/falko/mdsa-markdown-guide/actions/workflows/build.yml?query=branch%3Amain)

**Latest PDF: [MDTEST_1.0.pdf](https://github.com/falko/mdsa-markdown-guide/releases/latest/download/MDTEST_1.0.pdf)**
(built from `main` by the [workflow](https://github.com/falko/mdsa-markdown-guide/actions/workflows/build.yml?query=branch%3Amain), see the [release](https://github.com/falko/mdsa-markdown-guide/releases/tag/latest))

This repository is a small but complete OMG specification, written mostly in
Markdown and built with the containerized
[MDSA](https://github.com/ObjectManagementGroup/mdsa-omg-spec) (Model Driven
Specification Authoring) pipeline. It serves two purposes:

- **An example for authors.** The PDF explains how to write OMG specifications in
  Markdown, and the Markdown files are the examples: every feature the document
  describes is also used in it.
- **A test suite for the pipeline.** Building it exercises every Markdown feature OMG
  specifications need. If a change to the pipeline breaks one, `make check` or the
  checklist in Annex A shows it.

> **This is not a template.** Do not fork it or use it as the starting point for a new
> specification; it contains test content and changes that are still under review.
> Start from the official template
> [ObjectManagementGroup/mdsa-omg-spec](https://github.com/ObjectManagementGroup/mdsa-omg-spec)
> or the containerized
> [jasonmccsmith/containerized-spec](https://github.com/jasonmccsmith/containerized-spec),
> and use this repository to look up how things are done.

## What it shows

| Feature | Markdown syntax | Example in |
|---|---|---|
| One file per clause from Clause 7 on, included automatically | `07_Title.md`, `08_Title.md`, … | [`07_Markdown_in_the_MDSA_Pipeline.md`](07_Markdown_in_the_MDSA_Pipeline.md) to [`16_Known_Limitations.md`](16_Known_Limitations.md) |
| Numbered clauses and subclauses | `# Title` (never type numbers) | [`08_Sections.md`](08_Sections.md) |
| Unnumbered headings | `## Title {-}` | [`08_Sections.md`](08_Sections.md) |
| SVG figures with captions | `![Caption](Images/file.svg){#fig:id}` | [`07_Markdown_in_the_MDSA_Pipeline.md`](07_Markdown_in_the_MDSA_Pipeline.md), [`09_Figures.md`](09_Figures.md), [`Images/`](Images/) |
| Captioned tables, long tables | `Table: Caption {#tbl:id}` | [`05_Symbols.md`](05_Symbols.md), [`10_Tables.md`](10_Tables.md) |
| Links to sections, also between files: links on GitHub, section numbers in the PDF | `[Title](08_Sections.md#anchor)`, `[Title](#anchor)` | [`11_Cross-references.md`](11_Cross-references.md), all Markdown files |
| References to figures and tables | `@fig:id`, `@tbl:id` | [`11_Cross-references.md`](11_Cross-references.md) |
| Citations, normative and non-normative | `[@DMN16]` | [`12_Citations.md`](12_Citations.md), [`01_Scope.md`](01_Scope.md), [`specification.bib`](specification.bib) |
| Terms and definitions | definition lists | [`04_Terms.md`](04_Terms.md) |
| Lists, footnotes, code | standard Markdown | [`13_Other_Elements.md`](13_Other_Elements.md) |
| Notes | `> [!NOTE]` | [`15_Reviewing_on_GitHub.md`](15_Reviewing_on_GitHub.md) |
| Annexes | `# Title` in `A_Annexes.md` | [`A_Annexes.md`](A_Annexes.md) |
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

The technical content starts at Clause 7, with one file per clause, named after its
two-digit number and title (`07_Markdown_in_the_MDSA_Pipeline.md`, `08_Sections.md`,
…). The build includes all files from `07_` to `99_` in name order, so adding a
clause means adding its file; the two-digit numbers keep them in clause order, also
with ten or more clauses. A specification that needs a different order can list its
clause files in `07+_Technical_Content.tex` instead.

In every Markdown file, `#` is a clause and `##` a subclause. A clause file from
Clause 7 on starts with one `#` heading, its title. Files whose clause heading comes
from the template, such as `01_Scope.md`, start with `##` or with text.

## Made for GitHub's preview

Changes are mostly reviewed in GitHub's preview of the Markdown files, and with
a public source, anyone who knows Markdown should be able to fix a typo or
propose a change with a pull request. So the pipeline reads standard Markdown
the way GitHub does:

- Headings carry no identifiers. A section is referenced with an ordinary link to
  its heading, with the heading title as text: `[Figures](09_Figures.md#figures)`.
  GitHub shows the link; the PDF shows the section number instead ("Clause 9",
  "10.1", "Annex A", "A.2"), generated by the filter `section-links.lua` of
  `mdsa-omg-core`. The build warns if the link text is not the heading title.
- Lists and headings directly after a line of text, without a blank line, are
  lists and headings in the PDF too, as on GitHub. Before, they became plain text.
- Bare web addresses become links, and GitHub's `> [!NOTE]` blocks are supported.

[Clause 15](15_Reviewing_on_GitHub.md#reviewing-on-github) lists what GitHub shows
as typed (references to figures and tables, citations, captions) and what to avoid because GitHub and
the PDF show it differently, such as HTML or `H~2~O`.

## Building locally

Requirements: Docker, make and git.

```bash
make pandoc check
```

This builds the Docker image (the first time takes several minutes), builds the PDF
(`MDTEST_1.0.pdf`), and checks it for undefined references and citations and for
Markdown references that Pandoc did not process. It fails if it finds any.
`make pandoc build run` builds the PDF without the check.

Until the Markdown pipeline fixes are merged into `mdsa-omg-core`, build with a
checkout of the branch that contains them:

```bash
git clone -b markdown-pipeline-fixes https://github.com/falko/mdsa-omg-core ../mdsa-omg-core
make core=../mdsa-omg-core pandoc check
```

The `latest-ubuntu` Pandoc image may print "pandoc-crossref was compiled with pandoc
… but is being run through …" for each Markdown file. This warning can be ignored;
`make check` verifies the result.

## Continuous build

The workflow [`.github/workflows/build.yml`](.github/workflows/build.yml) runs the
same `make pandoc check` on every push and pull request, using this repository's own
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

## Status of the pipeline changes

This repository needs changes to the MDSA pipeline that are proposed upstream:

- [Pull requests to mdsa-omg-core](https://github.com/ObjectManagementGroup/mdsa-omg-core/pulls?q=is%3Apr+author%3Afalko):
  fixes for SVG images, tables, annexes and local overrides, cross-references and
  citations, a preamble generated from Pandoc's own template, lists of figures and
  tables, `make check`, and reading Markdown the way GitHub does (heading anchors,
  links to headings, lists and headings without blank lines); in a second step, zero-padded clause file names and the
  automatic inclusion of the clause files from Clause 7 on (older specifications with
  unpadded names keep working).
- [Pull requests to mdsa-omg-spec](https://github.com/ObjectManagementGroup/mdsa-omg-spec/pulls?q=is%3Apr+author%3Afalko):
  `mdsa-omg-core` submodule from the OMG repository; zero-padded clause file names.
- To follow for `containerized-spec` (already applied here in `Dockerfile` and
  `Makefile`): zero-padded clause file names, Inkscape and the `catchfile` LaTeX
  package for SVG images, `tlmgr update --self`, picking up new core versions without
  `make forcebuild`, and the `check`, `core=`, `pandoc_tag=`, `texlive_repository=`
  and `docker_build_opts=` options.

## Known limitations

- Terms in Clause 4 put the definition on the same line as the term.
- Code is formatted with the LaTeX `listings` package, which cannot handle non-ASCII
  characters such as curly quotes inside code.
- Visual aspects (layout, figure rendering, page breaks in tables) are not checked
  automatically; use the checklist in Annex A.

## Files

| File | Content |
|---|---|
| `01_Scope.md`, `04_Terms.md`, `05_Symbols.md` | Markdown content of Clauses 1, 4 and 5 |
| `07_Markdown_in_the_MDSA_Pipeline.md` … `16_Known_Limitations.md` | Clauses 7 to 16, one Markdown file each |
| `A_Annexes.md` | Annex A |
| `00_*.tex`, `02_*.tex`, `06_Additional.tex` | Clauses kept from the template (LaTeX) |
| `_Specification_Setup.tex`, `_Specification_AuthorSettings.tex` | Specification metadata and author settings |
| `specification.bib` | Bibliography entries of this specification |
| `Images/` | SVG figures |
| `Dockerfile`, `Makefile`, `Makefile.mdsa`, `user-pkgs.txt` | Containerized build, from `containerized-spec` with the changes listed above |
