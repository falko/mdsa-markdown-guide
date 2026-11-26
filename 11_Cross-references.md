# Cross-references

## Links to sections

Link to a section the way you would in any Markdown file on GitHub, with the
heading title as the link text:

```markdown
The tables are described in [Tables](10_Tables.md#tables).
Captions are explained in [Table captions](10_Tables.md#table-captions).
See [Identifiers](08_Sections.md#identifiers), and [Figures](09_Figures.md).
For a heading in the same file: [Links to sections](#links-to-sections).
```

On GitHub, these are links to the headings. In the PDF, each link is replaced
by the number of the section it points to:

> The tables are described in [Tables](10_Tables.md#tables). Captions are
> explained in [Table captions](10_Tables.md#table-captions). See
> [Identifiers](08_Sections.md#identifiers), and [Figures](09_Figures.md). For a
> heading in the same file: [Links to sections](#links-to-sections).

A whole clause is shown as "Clause" and its number, a whole annex as "Annex"
and its letter, and anything below as its number only, such as "10.1" or
"A.2". A link without an anchor, such as `09_Figures.md`, refers to the clause
of that file.

Because the link text is replaced, write the sentence so that it reads well
with either: `described in [Tables](10_Tables.md#tables)` becomes "described
in Clause 10". Do not write `click [here](#tables)` or
`the [Tables](#tables) clause`. The build warns when a link text is not the title
of the heading it links to.

Links to web pages stay links. Links to other files in the repository, such as
models, cannot be followed in the PDF; the build warns about them. Refer to
other documents with citations instead (see [Citations](12_Citations.md)).

## Figures and tables

Refer to a figure or table with `@` and its identifier:

| You write                      | Output                         |
|--------------------------------|--------------------------------|
| `@fig:build-pipeline`          | @fig:build-pipeline            |
| `@tbl:files`                   | @tbl:files                     |
| `[@tbl:prefixes; @tbl:files]`  | [@tbl:prefixes; @tbl:files]    |
| `@tbl:abbreviations` (other file) | @tbl:abbreviations          |

Table: References to figures and tables {#tbl:crossref-output}

GitHub shows these as typed: GitHub has no anchors for figures and tables.

## How cross-references work

Headings get GitHub's anchors as identifiers (pandoc's `gfm_auto_identifiers`),
and pandoc-crossref [@CROSSREF] prefixes them with `sec:`
(`autoSectionLabels`). The filter `section-links.lua` of `mdsa-omg-core` turns
each link to a heading into a reference to its prefixed identifier.
pandoc-crossref turns references to figures, tables and sections into a LaTeX
`\ref`, and LaTeX fills in the numbers, so references between files work.
