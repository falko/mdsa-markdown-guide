# Building and Testing {#sec:testing}

## Building the PDF {#sec:building}

Build the PDF with the containerized MDSA pipeline from the repository root:

```bash
make pandoc build run
```

The PDF is written to the repository root, named after the specification
acronym and version (`MDTEST_1.0.pdf`).

## Test checklist {#sec:checklist}

Check the generated PDF:

1. Clauses and subclauses are numbered once; the unnumbered subclause in
   @sec:sections has no number.
2. @fig:build-pipeline is shown with its caption, and the list of figures
   contains it.
3. The list of tables contains all captioned tables, from @tbl:abbreviations
   to @tbl:citations.
4. Every "Section", "Figure" and "Table" reference shows a number. No "??",
   no "¿", and no raw `@` reference appears anywhere.
5. Citations show "[DMN]", "[SCE]", "[UML]" and "[Pandoc]". DMN and UML
   appear under "Normative References", the others under "Non-normative
   References".
6. The header row of @tbl:long repeats on every page.
7. The terms in Clause 4 are formatted as a definition list.
