# Building and Testing

## Building the PDF

Build the PDF with the containerized MDSA pipeline from the repository root:

```bash
make pandoc build run
```

The PDF is written to the repository root, named after the specification
acronym and version (`MDTEST_1.0.pdf`).

## Test checklist

Check the generated PDF:

1. Clauses and subclauses are numbered once; the unnumbered subclause in
   [Sections](08_Sections.md) has no number.
2. [Build pipeline for Markdown content](Images/build-pipeline.svg) is shown with its caption, and the list of figures
   contains it.
3. The list of tables contains all captioned tables, from [Abbreviations](05_Symbols.md#table-abbreviations)
   to [Citation syntax and output](12_Citations.md#table-citation-syntax-and-output).
4. Every link to a section shows a number ("Clause 8", "11.1", "Annex A",
   "A.2"), and every link to a figure or table "Figure" or "Table" and a
   number. No "??", no "¿", and no raw `@` reference appears anywhere.
5. Citations show "[DMN]", "[SCE]", "[UML]" and "[Pandoc]". DMN and UML
   appear under "Normative References", the others under "Non-normative
   References".
6. The header row of
   [Long table that spans several pages](10_Tables.md#table-long-table-that-spans-several-pages)
   repeats on every page, and its caption is below its last row.
7. The terms in Clause 4 are formatted as a definition list.
8. The example links in [Links to sections](11_Cross-references.md#links-to-sections)
   show "Clause 10", "10.1", "8.2", "Clause 9" and "11.1", and the note in
   [Reviewing on GitHub](15_Reviewing_on_GitHub.md) is shown as a paragraph
   headed "Note".
9. Every table caption is below its table, and no `Table:` heading appears as a
   heading in the PDF.
10. On GitHub, no file shows `{#` anywhere, and every list and heading
    in GitHub's preview is also a list or heading in the PDF.
11. The horse 🐎 is shown in the text, inline code, code block and table of
    [Characters outside the Basic Multilingual Plane](13_Other_Elements.md#characters-outside-the-basic-multilingual-plane).
