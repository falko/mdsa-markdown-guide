This document describes how to write OMG specifications in Markdown with the
Model Driven Specification Architecture (MDSA) build pipeline, and at the same
time serves as its test suite.

Every Markdown feature described here is also used in this document. If a
feature does not work, the generated PDF shows it: a missing number, a "??"
or a raw `@` reference. Annex A (@sec:testing) lists what to check.

The document is a complete OMG specification built from the
[MDSA specification template](https://github.com/ObjectManagementGroup/mdsa-omg-spec).
Clauses 1, 4, 5 and 7 and later, and Annex A, are written in Markdown. The
other clauses are the template's LaTeX files. Specifications such as DMN
[@DMN16] can use this setup for their own source.

The pipeline itself is described in @sec:pipeline.
