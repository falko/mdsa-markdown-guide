# Cross-references {#sec:cross-references}

## Syntax {#sec:crossref-syntax}

Refer to a labelled element with `@` followed by its identifier:

| You write                      | Output                         |
|--------------------------------|--------------------------------|
| `@sec:figures`                 | @sec:figures                   |
| `@fig:build-pipeline`          | @fig:build-pipeline            |
| `@tbl:files`                   | @tbl:files                     |
| `[@tbl:prefixes; @tbl:files]`  | [@tbl:prefixes; @tbl:files]    |
| `@sec:testing` (other file)    | @sec:testing                   |

Table: Cross-reference syntax and output {#tbl:crossref-output}

References work across files: @sec:testing is in `A_Annexes.md`, and
@tbl:abbreviations is in `5_Symbols.md`.

## How cross-references work {#sec:crossref-how}

Pandoc reads `@fig:build-pipeline` as a citation. The filter pandoc-crossref
[@CROSSREF] turns references whose identifier starts with `sec:`, `fig:` or
`tbl:` into the word "Section", "Figure" or "Table" and a LaTeX `\ref`.
LaTeX fills in the number, so references between files work.
