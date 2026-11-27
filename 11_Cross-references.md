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

Links to the rules of a grammar work the same way and become "rule 2" or
"rule 2.i" in the PDF (see [Grammar rules](13_Other_Elements.md#grammar-rules)).

## Links to figures and tables

Figures and tables are referenced the same way: with a link whose text is the
caption. A link to a figure points to its image file (see
[Figures](09_Figures.md)), a link to a table to its caption heading (see
[Table captions](10_Tables.md#table-captions)). In the PDF, the link is
replaced by "Figure" or "Table" and the number:

###### Table: Links to figures and tables
| You write                                                              | PDF |
|------------------------------------------------------------------------|-----|
| `[Build pipeline for Markdown content](Images/build-pipeline.svg)`     | [Build pipeline for Markdown content](Images/build-pipeline.svg) |
| `[Abbreviations](05_Symbols.md#table-abbreviations)`                   | [Abbreviations](05_Symbols.md#table-abbreviations) |
| `[Link targets](08_Sections.md#table-link-targets)`                    | [Link targets](08_Sections.md#table-link-targets) |

On GitHub, a link to a figure opens the image, and a link to a table jumps to
its caption.

## How cross-references work

Headings get GitHub's anchors as identifiers (pandoc's `gfm_auto_identifiers`),
and pandoc-crossref [@CROSSREF] prefixes them with `sec:`
(`autoSectionLabels`). The filter `crossref-links.lua` of `mdsa-omg-core`
names each figure after its image file (`fig:build-pipeline`), turns each
`###### Table:` heading into the caption of the table below it
(`tbl:table-abbreviations`), and turns each link to a heading, image or table
caption into a reference. pandoc-crossref turns these references into a LaTeX
`\ref`, and LaTeX fills in the numbers, so references between files work.
