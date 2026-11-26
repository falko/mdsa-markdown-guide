# Known Limitations

- A reference to an annex reads "Section A", because pandoc-crossref uses one
  word per type of reference (`secPrefix`). Refer to annexes by subclause,
  e.g. [@sec:test-checklist](A_Annexes.md#test-checklist), or write "Annex A" as text.
- Terms in Clause 4 are formatted with the definition on the same line as
  the term. The LaTeX template example puts it on the next line.
- Code blocks are highlighted only for languages known to the LaTeX
  `listings` package. Other languages, such as FEEL, need a language
  definition in the template.
- GitHub's preview shows references, citations, table captions and figure
  attributes as typed (see [@sec:reviewing-on-github](15_Reviewing_on_GitHub.md#reviewing-on-github)).
