# Other Elements

## Text formatting

*Emphasis*, **strong emphasis**, `inline code` and
[links](https://www.omg.org) are written as usual in Markdown. A footnote is
written like this.[^note]

[^note]: Footnotes are numbered automatically.

## Lists

1. Numbered lists
    - can be nested,
    - with bullets on the second level.
2. Bullet lists:
    - first item
    - second item

## Code listings

Fenced code blocks become code listings. With a language after the opening
backticks, the code is highlighted, here as `xml`:

```xml
<definitions xmlns="https://www.omg.org/spec/DMN/20240513/MODEL/">
  <decision id="decision1" name="Decision 1"/>
</definitions>
```

Code is formatted by pandoc, not by the LaTeX `listings` package, so it may
contain characters such as curly quotes or dashes, which are often pasted in
from a word processor or a PDF by mistake. Inline code may too:
`name = ‘Decision 1’ – draft`.

```
// copied from a PDF: “quoted” and ‘single-quoted’ text, an ellipsis …
decision ‘Approve loan’ – status: “approved”
```
