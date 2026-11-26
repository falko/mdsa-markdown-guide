# Markdown in the MDSA Pipeline {#sec:pipeline}

## How Markdown files are built {#sec:how-built}

A specification repository created from the MDSA template contains one file
per clause, named with a two-digit clause number, such as `01_Scope.tex` for
Clause 1. Any of these files can be replaced by a Markdown file with the same
name and the extension `.md`, e.g. `01_Scope.md`. The build converts each
Markdown file to LaTeX with Pandoc [@PANDOC] and then includes it in the
specification template, as shown in @fig:build-pipeline.

The technical content starts at Clause 7 and has as many clauses as the
specification needs. Write each of them as a separate file, named after its
two-digit number and its title, such as `07_Markdown_in_the_MDSA_Pipeline.md`
for this clause. The build includes all files from `07_` to `99_` in the order
of their names, so the clause number in the file name defines the order. To add
a clause, create its file; to insert one, rename the files that follow it.

The two-digit numbers keep the files in clause order wherever they are listed,
also with ten or more clauses. A specification that needs a different order can
list its clause files in a file `07+_Technical_Content.tex`, one
`\subimport{}{...}` line per clause; that list then replaces the automatic one.

![Build pipeline for Markdown content](Images/build-pipeline.svg){#fig:build-pipeline width=80%}

Each Markdown file is converted separately, using the Pandoc settings in the
file `omgLaTeX.yaml`. The default settings come from `mdsa-omg-core`. A file
`omgLaTeX.yaml` in the specification repository replaces them.

## Files of this test suite {#sec:files}

@tbl:files lists the Markdown files of this document and the features they
test.

| File                                  | Clause  | Features tested                                |
|---------------------------------------|---------|------------------------------------------------|
| `01_Scope.md`                         | 1       | Citations, references to other files           |
| `04_Terms.md`                         | 4       | Definition lists                               |
| `05_Symbols.md`                       | 5       | Table with caption in a short file             |
| `07_Markdown_in_the_MDSA_Pipeline.md` | 7       | Figures, tables, citations                     |
| `08_Sections.md`                      | 8       | Numbered and unnumbered headings               |
| `09_Figures.md`                       | 9       | Figure syntax                                  |
| `10_Tables.md`                        | 10      | Captioned tables, long tables                  |
| `11_Cross-references.md`              | 11      | References within and between files            |
| `12_Citations.md`                     | 12      | Normative and non-normative references         |
| `13_Other_Elements.md`                | 13      | Lists, footnotes, code listings                |
| `14_Lists_of_Figures_and_Tables.md`   | 14      | Generated lists                                |
| `15_Known_Limitations.md`             | 15      | Bullet list                                    |
| `A_Annexes.md`                        | Annex A | Annex numbering, references back into clauses  |
| `specification.bib`                   | 3       | Specification-specific bibliography entries    |

Table: Markdown files of this test suite {#tbl:files}
