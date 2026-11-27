# Figures

An image that stands alone in its own paragraph becomes a figure. The text in
the square brackets is the caption:

```markdown
![Build pipeline for Markdown content](Images/build-pipeline.svg)
```

Store images as SVG files in the `Images` folder of the repository, with a
file name that says what the image shows. To refer to a figure, link to its
image file, with the caption as link text:

```markdown
The build steps are shown in [Build pipeline for Markdown content](Images/build-pipeline.svg).
```

On GitHub, the link opens the image. In the PDF, it is replaced by the figure
number: "The build steps are shown in
[Build pipeline for Markdown content](Images/build-pipeline.svg)." Each image
file can therefore be shown in only one figure.

Do not write the caption as a separate bold line below an image with empty
brackets (`![]`): the figure then gets no number, does not appear in the list
of figures, and cannot be referenced. Do not use HTML `<img>` tags either:
GitHub shows them, but the PDF leaves them out.
