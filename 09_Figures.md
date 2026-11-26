# Figures

An image that stands alone in its own paragraph becomes a figure. The text in
the square brackets is the caption:

```markdown
![Build pipeline for Markdown content](Images/build-pipeline.svg){#fig:build-pipeline}
```

Store images as SVG files in the `Images` folder of the repository. Do not
write the caption as a separate bold line below an image with empty brackets
(`![]`): the figure then gets no number, does not appear in the list of
figures, and cannot be referenced.

GitHub shows the image and its caption text, followed by the attributes in
braces as text. Keep them short: the identifier is needed for references, but
a size such as `width=80%` is only needed if the image is too large in the PDF.
Do not use HTML `<img>` tags: GitHub shows them, but the PDF leaves them out.
