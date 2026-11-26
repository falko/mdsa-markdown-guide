This document describes how to write OMG specifications in Markdown with the
Model Driven Specification Authoring (MDSA) build pipeline, and at the same
time serves as its test suite.

Every Markdown feature described here is also used in this document. If a
feature does not work, the generated PDF shows it: a missing number, a "??"
or a raw `@` reference. [Test checklist](A_Annexes.md#test-checklist) lists what to check.

The document is a complete OMG specification built from the containerized
version of the
[MDSA specification template](https://github.com/ObjectManagementGroup/mdsa-omg-spec).
Clauses 1, 4 and 5, each of Clauses 7 to 16, and Annex A are separate Markdown
files. The other clauses are the template's LaTeX files. Specifications such as
DMN [@DMN16] can use this setup for their own source.

The pipeline itself is described in
[Markdown in the MDSA Pipeline](07_Markdown_in_the_MDSA_Pipeline.md).
