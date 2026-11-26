# Cross-references

## Syntax

Refer to a labelled element with `@` followed by its identifier:

| You write                      | Output                         |
|--------------------------------|--------------------------------|
| `@sec:figures`                 | @sec:figures                   |
| `@fig:build-pipeline`          | @fig:build-pipeline            |
| `@tbl:files`                   | @tbl:files                     |
| `[@tbl:prefixes; @tbl:files]`  | [@tbl:prefixes; @tbl:files]    |
| `@sec:building-and-testing` (other file)    | @sec:building-and-testing                   |

Table: Cross-reference syntax and output {#tbl:crossref-output}

References work across files: @sec:building-and-testing is in `A_Annexes.md`, and
@tbl:abbreviations is in `05_Symbols.md`. A section is referenced by the
identifier GitHub uses for its heading (see @sec:identifiers).

On GitHub, a reference is shown as written, e.g. `@sec:figures`. It reads well
but is not a link.

## Links to sections

A Markdown link to a heading, as GitHub creates it, also works in the PDF. The
link text stays as written, so use it where a reader should be able to click
through on GitHub, and a reference where the PDF needs the number:

| You write                            | GitHub          | PDF                  |
|--------------------------------------|-----------------|----------------------|
| `[Figures](#figures)`                | link            | link "Figures"       |
| `[Figures](09_Figures.md#figures)`   | link            | link "Figures"       |
| `@sec:figures`                       | text            | "Section" and number |

Table: References and links to sections {#tbl:links}

Example: the figures clause, [Figures](09_Figures.md#figures), and the
[identifiers](08_Sections.md#identifiers) of sections.

## How cross-references work

Pandoc reads `@fig:build-pipeline` as a citation. The filter pandoc-crossref
[@CROSSREF] turns references whose identifier starts with `sec:`, `fig:` or
`tbl:` into the word "Section", "Figure" or "Table" and a LaTeX `\ref`.
LaTeX fills in the number, so references between files work.

Headings get GitHub's identifiers from pandoc (`gfm_auto_identifiers`), and
pandoc-crossref adds the `sec:` prefix to them (`autoSectionLabels`). A small
filter of `mdsa-omg-core`, `gfm-heading-links.lua`, points links to headings,
such as `#figures` or `09_Figures.md#figures`, to the prefixed identifier.
