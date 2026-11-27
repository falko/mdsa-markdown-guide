# Tables

## Table captions

A level-6 heading that starts with `Table:`, directly before a table, is the
table's caption:

```markdown
###### Table: Syntax per feature

| Feature | Syntax                     |
|---------|----------------------------|
| Figure  | `![Caption](file.svg)`     |
```

On GitHub, the caption is a small heading above the table, and it appears in
the file's outline. In the PDF, it becomes the numbered caption below the
table. To refer to a table, link to its caption heading, with the caption as
link text; the anchor is the caption heading's text in GitHub's form:

```markdown
The syntax is listed in [Syntax per feature](#table-syntax-per-feature).
```

Column widths are computed from the contents of the columns, so the dashes in
the separator row of a pipe table do not matter.

All captioned tables, such as [Link targets](08_Sections.md#table-link-targets)
and [Abbreviations](05_Symbols.md#table-abbreviations), are numbered and appear in
the list of tables. A `Table:` heading that is not directly followed by a table
stays a heading, and the build warns about it.

## Merged cells and rich cell content

Pipe tables cannot merge cells and cannot hold several paragraphs, lists or
code blocks in a cell. For such tables, write the table structure in HTML and
the contents of the cells in Markdown, with a blank line after each opening
`<td>` or `<th>` tag and before its closing tag. GitHub shows such tables
correctly, and the build reads them into the same table model as pipe tables.
The rest of this subclause uses excerpts from DMN 1.7.

Merged cells use the HTML attributes `rowspan` and `colspan`:

```html
<table>
<tr><th>FEEL value</th><th>Java</th><th>XML</th><th>PMML</th></tr>
<tr><td rowspan="2">number</td><td rowspan="2">

`java.math.BigDecimal`

</td><td>decimal</td><td>decimal, PROB-NUMBER</td></tr>
<tr><td>integer</td><td>integer, INT-NUMBER</td></tr>
</table>
```

###### Table: Mapping between FEEL and other domains (excerpt)
<table>
<tr><th>FEEL value</th><th>Java</th><th>XML</th><th>PMML</th><th>ONNX</th></tr>
<tr><td rowspan="3">number</td><td rowspan="3">

`java.math.BigDecimal`

</td><td>decimal</td><td>decimal, PROB-NUMBER, PERCENTAGE-NUMBER</td><td rowspan="3">FLOAT, UINT8, INT8, INT16, INT32, INT64, DOUBLE</td></tr>
<tr><td>integer</td><td>integer, INT-NUMBER</td></tr>
<tr><td>double</td><td>double, REAL-NUMBER</td></tr>
<tr><td>string</td><td>

`java.lang.String`

</td><td>string</td><td>string, FIELD-NAME</td><td>STRING</td></tr>
<tr><td>boolean</td><td>

`java.lang.Boolean`

</td><td>boolean</td><td>boolean</td><td>BOOL</td></tr>
</table>

A cell can hold several paragraphs, lists and code, and footnotes, which are
printed below the table:

###### Table: Built-in string functions (excerpt)
<table>
<tr><th>Name(parameters)</th><th>Parameter domain</th><th>Description</th><th>Example</th></tr>
<tr>
<td>

`substring(string, start position, length?)`

</td>
<td>

string, number[^start]

</td>
<td>

Returns *length* (or all) characters in *string*, starting at *start
position*.

The first position is 1, the last position is -1.

</td>
<td>

`substring("foobar", 3) = "obar"`

`substring("foobar", -2, 1) = "a"`

</td>
</tr>
<tr>
<td>

`string length(string)`

</td>
<td>

string

</td>
<td>

Returns the number of characters (or code points) in *string*, for
example:

- `"foo"`: 3
- `"🐎ab"`: 3, see
  [Characters outside the Basic Multilingual Plane](13_Other_Elements.md#characters-outside-the-basic-multilingual-plane)

</td>
<td>

`string length("foo") = 3`

</td>
</tr>
</table>

[^start]: A start position of 0 is treated like 1.

Pipe tables are enough for simpler content: math, images, and line breaks
written as `<br>`:

###### Table: Semantics of addition and subtraction (excerpt)
| type($e_1$) | type($e_2$) | $e_1 + e_2$, $e_1 - e_2$ | result type |
|-------------|-------------|--------------------------|-------------|
| number      | number      | $\mathrm{value}^{-1}(\mathrm{value}(e_1) \pm \mathrm{value}(e_2))$ | number |
| date and time | days and time<br>duration | see the date and time arithmetic | date and time |

###### Table: DRD elements and their notation (excerpt)
| Element                    | Notation                                  |
|----------------------------|-------------------------------------------|
| Decision                   | ![Decision](Images/dmn-decision.svg)      |
| Input<br>Data              | ![Input Data](Images/dmn-input-data.svg)  |

A table without a caption heading has no number and no entry in the list of
tables:

| Hit policy | Meaning     |
|------------|-------------|
| U          | Unique      |
| F          | First       |

## Specification-specific table styles

All tables have the OMG style: a full grid, header rows in bold, the caption
below the table. A specification can give some of its tables their own style,
with a filter `specification.lua` in its repository (see
[How Markdown files are built](07_Markdown_in_the_MDSA_Pipeline.md#how-markdown-files-are-built)).
This document has one, as an example: it draws DMN decision tables in the
notation of DMN 1.7, 8.2. The table is written in HTML; a `<colgroup>` marks
each column as hit policy, input, output or annotation, the hit policy cell
spans the clause rows, allowed values have the class `values`, and the caption
is the name of the decision. Italics are written by the author, because in DMN
they mean string literals:

```html
<table class="dmn-decision-table">
<caption>Discount</caption>
<colgroup><col class="hit-policy"><col class="input"><col class="input"><col class="input"><col class="output"></colgroup>
<thead>
<tr><th rowspan="2">U</th><th>Customer</th><th>OrderSize</th><th>Delivery</th><th>Discount</th></tr>
<tr><td class="values"><em>Business</em>, <em>Private</em>, <em>Government</em></td>...</tr>
</thead>
<tbody>
<tr><td>1</td><td rowspan="2"><em>Business</em></td><td>&lt;10</td><td>-</td><td>0.05</td></tr>
...
```

GitHub shows such a table with a grid and merged cells. The PDF follows the
notation: the name box above and adjoining the table, double lines between the
input and output columns, between the output and annotation columns and below
the clauses, and the clauses shaded per column group, while the hit policy
cell, the allowed values and the entries stay white. This is DMN Figure 8-6:

<table class="dmn-decision-table">
<caption>Discount</caption>
<colgroup><col class="hit-policy"><col class="input"><col class="input"><col class="input"><col class="output"></colgroup>
<thead>
<tr><th rowspan="2">U</th><th>Customer</th><th>OrderSize</th><th>Delivery</th><th>Discount</th></tr>
<tr><td class="values"><em>Business</em>, <em>Private</em>, <em>Government</em></td><td class="values">&lt;10, &gt;=10</td><td class="values"><em>sameday</em>, <em>slow</em></td><td class="values">0, 0.05, 0.10, 0.15</td></tr>
</thead>
<tbody>
<tr><td>1</td><td rowspan="2"><em>Business</em></td><td>&lt;10</td><td>-</td><td>0.05</td></tr>
<tr><td>2</td><td>&gt;=10</td><td>-</td><td>0.10</td></tr>
<tr><td>3</td><td rowspan="2"><em>Private</em></td><td rowspan="2">-</td><td><em>sameday</em></td><td>0</td></tr>
<tr><td>4</td><td><em>slow</em></td><td>0.05</td></tr>
<tr><td>5</td><td><em>Government</em></td><td>-</td><td>-</td><td>0.15</td></tr>
</tbody>
</table>

A table with two output components and an annotation column (DMN Figure 8-19,
with the double line before the annotation column that 8.2.1 requires). Inputs
without allowed values have an empty `values` cell:

<table class="dmn-decision-table">
<caption>Routing rules</caption>
<colgroup><col class="hit-policy"><col class="input"><col class="input"><col class="input"><col class="output"><col class="output"><col class="annotation"></colgroup>
<thead>
<tr><th rowspan="2">O</th><th>Age</th><th>Risk category</th><th>Debt review</th><th>Routing</th><th>Review level</th><th>Reason</th></tr>
<tr><td class="values"></td><td class="values"><em>LOW</em>, <em>MEDIUM</em>, <em>HIGH</em></td><td class="values"></td><td class="values"><em>DECLINE</em>, <em>REFER</em>, <em>ACCEPT</em></td><td class="values"><em>LEVEL 2</em>, <em>LEVEL 1</em>, <em>NONE</em></td><td class="values"></td></tr>
</thead>
<tbody>
<tr><td>1</td><td>-</td><td>-</td><td>-</td><td><em>ACCEPT</em></td><td><em>NONE</em></td><td><em>Acceptable</em></td></tr>
<tr><td>2</td><td>&lt; 18</td><td>-</td><td>-</td><td><em>DECLINE</em></td><td><em>NONE</em></td><td><em>Applicant too young</em></td></tr>
<tr><td>3</td><td>-</td><td><em>HIGH</em></td><td>-</td><td><em>REFER</em></td><td><em>LEVEL 1</em></td><td><em>High risk application</em></td></tr>
<tr><td>4</td><td>-</td><td>-</td><td>true</td><td><em>REFER</em></td><td><em>LEVEL 2</em></td><td><em>Applicant under debt review</em></td></tr>
</tbody>
</table>

An output label above several output components spans their columns, and the
hit policy cell spans all three clause rows (DMN Figure 8-12):

<table class="dmn-decision-table">
<caption>information item name</caption>
<colgroup><col class="hit-policy"><col class="input"><col class="input"><col class="output"><col class="output"></colgroup>
<thead>
<tr><th rowspan="3">H</th><th rowspan="2">input expression 1</th><th rowspan="2">input expression 2</th><th colspan="2">output label</th></tr>
<tr><th>output component 1</th><th>output component 2</th></tr>
<tr><td class="values">input value 1a, input value 1b</td><td class="values">input value 2a, input value 2b</td><td class="values">output value 1a, output value 1b</td><td class="values">output value 2a, output value 2b</td></tr>
</thead>
<tbody>
<tr><td>1</td><td rowspan="2">input entry 1a</td><td>input entry 2a</td><td>output entry 1.1</td><td>output entry 2.1</td></tr>
<tr><td>2</td><td>input entry 2b</td><td>output entry 1.2</td><td>output entry 2.2</td></tr>
<tr><td>3</td><td>input entry 1b</td><td>-</td><td>output entry 1.3</td><td>output entry 2.3</td></tr>
</tbody>
</table>

Rules as columns and crosstab tables (DMN Figures 8-7 to 8-11) are not
implemented in this example filter.

The file `dmn-notation.css` in this repository draws the same notation in a web
browser, from the same HTML.

Settings that apply to all tables of a specification go into
`_Specification_AuthorSettings.tex`. For example, DMN puts table captions above
the tables:

```latex
\omgtablecaptionabove
```

## Long tables

Tables continue across page breaks.
[Long table that spans several pages](#table-long-table-that-spans-several-pages)
has enough rows to need more than one page. Its header row must repeat on
every page, and its caption is below its last row.

###### Table: Long table that spans several pages
| Row | Purpose                                         |
|-----|-------------------------------------------------|
| 1   | Filler row 1 to force a page break in the table |
| 2   | Filler row 2 to force a page break in the table |
| 3   | Filler row 3 to force a page break in the table |
| 4   | Filler row 4 to force a page break in the table |
| 5   | Filler row 5 to force a page break in the table |
| 6   | Filler row 6 to force a page break in the table |
| 7   | Filler row 7 to force a page break in the table |
| 8   | Filler row 8 to force a page break in the table |
| 9   | Filler row 9 to force a page break in the table |
| 10  | Filler row 10 to force a page break in the table |
| 11  | Filler row 11 to force a page break in the table |
| 12  | Filler row 12 to force a page break in the table |
| 13  | Filler row 13 to force a page break in the table |
| 14  | Filler row 14 to force a page break in the table |
| 15  | Filler row 15 to force a page break in the table |
| 16  | Filler row 16 to force a page break in the table |
| 17  | Filler row 17 to force a page break in the table |
| 18  | Filler row 18 to force a page break in the table |
| 19  | Filler row 19 to force a page break in the table |
| 20  | Filler row 20 to force a page break in the table |
| 21  | Filler row 21 to force a page break in the table |
| 22  | Filler row 22 to force a page break in the table |
| 23  | Filler row 23 to force a page break in the table |
| 24  | Filler row 24 to force a page break in the table |
| 25  | Filler row 25 to force a page break in the table |
| 26  | Filler row 26 to force a page break in the table |
| 27  | Filler row 27 to force a page break in the table |
| 28  | Filler row 28 to force a page break in the table |
| 29  | Filler row 29 to force a page break in the table |
| 30  | Filler row 30 to force a page break in the table |
| 31  | Filler row 31 to force a page break in the table |
| 32  | Filler row 32 to force a page break in the table |
| 33  | Filler row 33 to force a page break in the table |
| 34  | Filler row 34 to force a page break in the table |
| 35  | Filler row 35 to force a page break in the table |
| 36  | Filler row 36 to force a page break in the table |
| 37  | Filler row 37 to force a page break in the table |
| 38  | Filler row 38 to force a page break in the table |
| 39  | Filler row 39 to force a page break in the table |
| 40  | Filler row 40 to force a page break in the table |
| 41  | Filler row 41 to force a page break in the table |
| 42  | Filler row 42 to force a page break in the table |
| 43  | Filler row 43 to force a page break in the table |
| 44  | Filler row 44 to force a page break in the table |
| 45  | Filler row 45 to force a page break in the table |
| 46  | Filler row 46 to force a page break in the table |
| 47  | Filler row 47 to force a page break in the table |
| 48  | Filler row 48 to force a page break in the table |
| 49  | Filler row 49 to force a page break in the table |
| 50  | Filler row 50 to force a page break in the table |
| 51  | Filler row 51 to force a page break in the table |
| 52  | Filler row 52 to force a page break in the table |
| 53  | Filler row 53 to force a page break in the table |
| 54  | Filler row 54 to force a page break in the table |
| 55  | Filler row 55 to force a page break in the table |
| 56  | Filler row 56 to force a page break in the table |
| 57  | Filler row 57 to force a page break in the table |
| 58  | Filler row 58 to force a page break in the table |
| 59  | Filler row 59 to force a page break in the table |
| 60  | Filler row 60 to force a page break in the table |
