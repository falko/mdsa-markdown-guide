# Figures {#sec:figures}

An image that stands alone in its own paragraph becomes a figure. The text in
the square brackets is the caption:

```markdown
![Build pipeline for Markdown content](Images/build-pipeline.svg){#fig:build-pipeline width=80%}
```

Store images as SVG files in the `Images` folder of the repository. Do not
write the caption as a separate bold line below an image with empty brackets
(`![]`): the figure then gets no number, does not appear in the list of
figures, and cannot be referenced.
