# Reviewing on GitHub

Changes to a specification are mostly reviewed in GitHub's rendered preview of
the Markdown files, not in the PDF. And when the source of a specification is
public, anyone who knows Markdown should be able to fix a typo or propose a
change with a pull request, without learning the build pipeline first. The
pipeline therefore reads Markdown the way GitHub does, and specifications
should use standard Markdown wherever possible:

- Pandoc reads lists, headings and block quotes that follow a line of text
  without a blank line in between, as GitHub does. Without this, such a list
  or heading would look right on GitHub but be plain text in the PDF.
- Links to headings are ordinary Markdown links, which work on GitHub and
  become section numbers in the PDF (see
  [Links to sections](11_Cross-references.md#links-to-sections)).
- Web addresses such as https://www.omg.org become links in both.

@tbl:github lists how GitHub shows the Markdown elements of a specification.

| Element                          | Markdown                         | GitHub preview               |
|----------------------------------|----------------------------------|------------------------------|
| Headings                         | `# Title`                        | as in the PDF, unnumbered    |
| Figures                          | `![Caption](file.svg){#fig:id}`  | image, then `{#fig:id}` text |
| Tables                           | pipe tables                      | as in the PDF                |
| Table captions                   | `Table: Caption {#tbl:id}`       | text paragraph               |
| Links to sections                | `[Title](File.md#anchor)`        | link (PDF: section number)   |
| References to figures, tables    | `@fig:id`, `@tbl:id`             | text                         |
| Citations                        | `[@DMN16]`                       | text                         |
| Footnotes                        | `[^note]`                        | as in the PDF                |
| Notes                            | `> [!NOTE]`                      | note box                     |
| Definition lists (Clause 4)      | `Term` and `: Definition`        | one paragraph                |
| Code                             | fenced code blocks               | as in the PDF                |

Table: Markdown elements in GitHub's preview {#tbl:github}

> [!NOTE]
> This is a note written with GitHub's syntax for notes. The PDF shows it as a
> paragraph headed "Note".

Avoid the following, because GitHub and the PDF show them differently:

- HTML, such as `<img>`, `<br>` or `<sub>`: GitHub shows it, but the PDF
  leaves it out. HTML comments (`<!-- ... -->`) are fine for remarks to
  reviewers; neither shows them.
- `H~2~O` and `x^2^` for subscript and superscript: GitHub shows the first as
  struck through and the second as typed.
- Inline footnotes (`^[text]`), fenced divs (`:::`), bracketed spans
  (`[text]{.class}`) and lettered lists (`a.`): GitHub shows them as typed.
- Grid tables and multiline tables: GitHub shows them as typed. Use pipe
  tables.
- A vertical bar inside inline code in a table cell: GitHub ends the cell
  there, and the escaped form shows the backslash in the PDF. Describe such
  code in the text instead.
- LaTeX commands in the text, such as `\newpage`: GitHub shows them as typed.
