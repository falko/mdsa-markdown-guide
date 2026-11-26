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

References work across files: [@sec:building-and-testing](A_Annexes.md#building-and-testing) is in `A_Annexes.md`, and
@tbl:abbreviations is in `05_Symbols.md`. A section is referenced by the
identifier GitHub uses for its heading (see
[@sec:identifiers](08_Sections.md#identifiers)).

## Links to sections

On GitHub, a reference such as `@sec:figures` is shown as typed and is not a
link. To make a reference to a section clickable on GitHub, write it as the
text of a link to the heading:

```markdown
[@sec:figures](09_Figures.md#figures)
[@sec:identifiers](#identifiers)
```

GitHub shows a link `@sec:figures` to the heading; the PDF shows only the
reference, e.g. [@sec:figures](09_Figures.md#figures). Leave out the file name
for a heading in the same file. Use this form for all references to sections.
If the reference and the link point to different headings, the build prints a
warning.

A link with its own text also works in the PDF, as a link with that text.
Use it where the text names the section instead of numbering it:

| You write                               | GitHub                 | PDF                  |
|-----------------------------------------|------------------------|----------------------|
| `[@sec:figures](09_Figures.md#figures)` | link `@sec:figures`    | "Section" and number |
| `@sec:figures`                          | text `@sec:figures`    | "Section" and number |
| `[Figures](09_Figures.md#figures)`      | link "Figures"         | link "Figures"       |

Table: References and links to sections {#tbl:links}

Example of a link with its own text: the clause on
[Figures](09_Figures.md#figures).

Figures and tables are referenced only as `@fig:...` and `@tbl:...`: GitHub
has no anchors for them.

## How cross-references work

Pandoc reads `@fig:build-pipeline` as a citation. The filter pandoc-crossref
[@CROSSREF] turns references whose identifier starts with `sec:`, `fig:` or
`tbl:` into the word "Section", "Figure" or "Table" and a LaTeX `\ref`.
LaTeX fills in the number, so references between files work.

Headings get GitHub's identifiers from pandoc (`gfm_auto_identifiers`), and
pandoc-crossref adds the `sec:` prefix to them (`autoSectionLabels`). A small
filter of `mdsa-omg-core`, `gfm-heading-links.lua`, keeps only the reference
of a link like `[@sec:figures](#figures)`, and points other links to headings,
such as `#figures` or `09_Figures.md#figures`, to the prefixed identifier.
