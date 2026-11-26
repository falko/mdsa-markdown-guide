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

Fenced code blocks become code listings. Use only languages known to the
LaTeX `listings` package, such as `xml`:

```xml
<definitions xmlns="https://www.omg.org/spec/DMN/20240513/MODEL/">
  <decision id="decision1" name="Decision 1"/>
</definitions>
```
