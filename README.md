# MDSA Markdown Test Suite

A small OMG specification, written mostly in Markdown, that serves two purposes:

1. **Test suite** for the containerized MDSA build pipeline: building it exercises
   every Markdown feature OMG specifications need, so a pipeline change can be
   checked by building this document and going through the checklist in Annex A.
2. **Reference** for authors: the PDF explains how to write OMG specifications in
   Markdown with the MDSA pipeline, and the Markdown files are the examples.

It was created from the template
[jasonmccsmith/containerized-spec](https://github.com/jasonmccsmith/containerized-spec)
(commit d05143c) and uses the same build.

## Features covered

| Feature | Where |
|---|---|
| Numbered and unnumbered headings, clause structure | `7+_Technical_Content.md` |
| Figures (SVG) with captions | `7+_Technical_Content.md`, `Images/` |
| Captioned tables, long tables over page breaks | `5_Symbols.md`, `7+_Technical_Content.md` |
| Cross-references within and between files (pandoc-crossref) | all Markdown files |
| Citations, normative and non-normative references (biblatex) | `1_Scope.md`, `4_Terms.md`, `specification.bib` |
| Definition lists (terms) | `4_Terms.md` |
| Lists, footnotes, inline code, code listings | `7+_Technical_Content.md` |
| Annexes | `A_Annexes.md` |
| Table of contents, list of figures, list of tables | generated |

## Building

```bash
make pandoc check
```

This builds the PDF (`MDTEST_1.0.pdf`) and then checks the build for undefined
references and citations and for Markdown references that pandoc did not process.
It fails if it finds any. `make pandoc build run` builds the PDF without the check.
The visual aspects (layout, figure rendering, page breaks in tables) still need to be
checked against the checklist in Annex A.

This test suite currently needs proposed changes to `mdsa-omg-core`
(branch `markdown-pipeline-fixes`). Until they are published, build with a local
checkout of that branch:

```bash
make core=../mdsa-omg-core pandoc check
```

The `latest-ubuntu` pandoc image may print "pandoc-crossref was compiled with pandoc
… but is being run through …" for each Markdown file. This warning can be ignored;
`make check` verifies the result.

## Changes to the template in this repository

These changes to the template files are proposed for `containerized-spec` as well:

- `Makefile`: `check` target; optional `pandoc_tag=` (pin the `pandoc/latex` image
  version), `texlive_repository=` (fixed CTAN mirror for tlmgr) and `core=` (local
  `mdsa-omg-core` checkout) variables.
- `Dockerfile`: optional `TEXLIVE_REPOSITORY` build argument; `inkscape` and the
  `catchfile` LaTeX package, which the `svg` package needs to convert SVG images;
  `tlmgr update --self` before installing packages.
- `Dockerfile` and `Makefile`: new versions of `mdsa-omg-core` and `mdsa-tools` are
  picked up without `make forcebuild` (commit lookup with `git ls-remote`, falling
  back to the version stored in the image if the lookup fails).
- `_Specification_AuthorSettings.tex`: `showstringspaces=false` for code listings.
