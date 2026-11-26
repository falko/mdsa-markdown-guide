# Markdown in the MDSA Pipeline {#sec:pipeline}

## How Markdown files are built {#sec:how-built}

A specification repository created from the MDSA template contains one file
per clause, such as `1_Scope.tex` for Clause 1. Any of these files can be
replaced by a Markdown file with the same name and the extension `.md`, e.g.
`1_Scope.md`. The build converts each Markdown file to LaTeX with Pandoc
[@PANDOC] and then includes it in the specification template, as shown in
@fig:build-pipeline.

The technical content starts at Clause 7 and has as many clauses as the
specification needs. Write each of them as a separate file, named after its
number and title, such as `7_Markdown_in_the_MDSA_Pipeline.md` for this clause.
The file `7+_Technical_Content.tex` lists these files in order, one
`\subimport{}{...}` line per clause (without the extension):

```latex
\subimport{}{7_Markdown_in_the_MDSA_Pipeline}
\subimport{}{8_Sections}
```

To add a clause, create its file and add its line there.

![Build pipeline for Markdown content](Images/build-pipeline.svg){#fig:build-pipeline width=80%}

Each Markdown file is converted separately, using the Pandoc settings in the
file `omgLaTeX.yaml`. The default settings come from `mdsa-omg-core`. A file
`omgLaTeX.yaml` in the specification repository replaces them.

## Files of this test suite {#sec:files}

@tbl:files lists the Markdown files of this document and the features they
test.

| File                                | Clause  | Features tested                                |
|-------------------------------------|---------|------------------------------------------------|
| `1_Scope.md`                        | 1       | Citations, references to other files           |
| `4_Terms.md`                        | 4       | Definition lists                               |
| `5_Symbols.md`                      | 5       | Table with caption in a short file             |
| `7_Markdown_in_the_MDSA_Pipeline.md`| 7       | Figures, tables, citations                     |
| `8_Sections.md`                     | 8       | Numbered and unnumbered headings               |
| `9_Figures.md`                      | 9       | Figure syntax                                  |
| `10_Tables.md`                      | 10      | Captioned tables, long tables                  |
| `11_Cross-references.md`            | 11      | References within and between files            |
| `12_Citations.md`                   | 12      | Normative and non-normative references         |
| `13_Other_Elements.md`              | 13      | Lists, footnotes, code listings                |
| `14_Lists_of_Figures_and_Tables.md` | 14      | Generated lists                                |
| `15_Known_Limitations.md`           | 15      | Bullet list                                    |
| `7+_Technical_Content.tex`          | 7–15    | Order of the clause files                      |
| `A_Annexes.md`                      | Annex A | Annex numbering, references back into clauses  |
| `specification.bib`                 | 3       | Specification-specific bibliography entries    |

Table: Markdown files of this test suite {#tbl:files}
