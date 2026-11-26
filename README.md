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
| Numbered clauses and subclauses | `# Title {#sec:id}` (never type numbers) | [`7+_Technical_Content.md`](7+_Technical_Content.md) |
| Unnumbered headings | `## Title {-}` | [`7+_Technical_Content.md`](7+_Technical_Content.md) |
| SVG figures with captions | `![Caption](Images/file.svg){#fig:id}` | [`7+_Technical_Content.md`](7+_Technical_Content.md), [`Images/`](Images/) |
| Captioned tables, long tables | `Table: Caption {#tbl:id}` | [`5_Symbols.md`](5_Symbols.md), [`7+_Technical_Content.md`](7+_Technical_Content.md) |
| Cross-references, also between files | `@sec:id`, `@fig:id`, `@tbl:id` | all Markdown files |
| Citations, normative and non-normative | `[@DMN16]` | [`1_Scope.md`](1_Scope.md), [`specification.bib`](specification.bib) |
| Terms and definitions | definition lists | [`4_Terms.md`](4_Terms.md) |
| Lists, footnotes, code | standard Markdown | [`7+_Technical_Content.md`](7+_Technical_Content.md) |
| Annexes | `# Title` in `A_Annexes.md` | [`A_Annexes.md`](A_Annexes.md) |
| Table of contents, lists of figures and tables | generated | — |

## How it works

Each clause of an MDSA specification is a file, such as `1_Scope.tex`. A Markdown
file with the same name (`1_Scope.md`) replaces it. The build converts each Markdown
file to LaTeX with [Pandoc](https://pandoc.org/), resolves cross-references with
[pandoc-crossref](https://lierdakil.github.io/pandoc-crossref/), and builds the PDF
with the OMG LaTeX templates from
[mdsa-omg-core](https://github.com/ObjectManagementGroup/mdsa-omg-core). Everything
runs in a Docker container, so no local LaTeX or Pandoc installation is needed.

In every Markdown file, `#` is a clause and `##` a subclause. Files whose clause
heading comes from the template, such as `1_Scope.md`, start with `##` or with text.

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
  tables, and `make check`.
- [Pull requests to mdsa-omg-spec](https://github.com/ObjectManagementGroup/mdsa-omg-spec/pulls?q=is%3Apr+author%3Afalko):
  `mdsa-omg-core` submodule from the OMG repository.
- To follow for `containerized-spec` (already applied here in `Dockerfile` and
  `Makefile`): Inkscape and the `catchfile` LaTeX package for SVG images,
  `tlmgr update --self`, picking up new core versions without `make forcebuild`, and
  the `check`, `core=`, `pandoc_tag=`, `texlive_repository=` and `docker_build_opts=`
  options.

## Known limitations

- References to annexes read "Section A" (one prefix word per type of reference).
- Terms in Clause 4 put the definition on the same line as the term.
- Code is formatted with the LaTeX `listings` package, which cannot handle non-ASCII
  characters such as curly quotes inside code.
- Visual aspects (layout, figure rendering, page breaks in tables) are not checked
  automatically; use the checklist in Annex A.

## Files

| File | Content |
|---|---|
| `1_Scope.md`, `4_Terms.md`, `5_Symbols.md`, `7+_Technical_Content.md`, `A_Annexes.md` | The Markdown content |
| `0_*.tex`, `2_*.tex`, `6_Additional.tex` | Clauses kept from the template (LaTeX) |
| `_Specification_Setup.tex`, `_Specification_AuthorSettings.tex` | Specification metadata and author settings |
| `specification.bib` | Bibliography entries of this specification |
| `Images/` | SVG figures |
| `Dockerfile`, `Makefile`, `Makefile.mdsa`, `user-pkgs.txt` | Containerized build, from `containerized-spec` with the changes listed above |
