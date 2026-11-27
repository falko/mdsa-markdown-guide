#!/usr/bin/env bash
# Converts the DMN Word source into the Markdown clause files and SVG images of
# this repository. Run from the repository root:
#
#   tools/convert.sh DMN_1.7_SOURCE.docx DMN_1.7_SOURCE.pdf [OUTDIR]
#
# The PDF made from the Word document is used to cut out the figures that
# Word draws as tables or text boxes (boxed expressions). Needs pandoc 3,
# python3 and poppler (pdftotext, pdftoppm, pdftocairo). Writes the clause
# files (01_, 02_, 06_, 07_ to 16_, A_Annexes.md) and Images/ into OUTDIR
# (default: the repository root), and the notes of the conversion into
# OUTDIR/convert.log.
set -euo pipefail

docx=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
pdf=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
root=$(cd "$(dirname "$0")/.." && pwd)
out=${3:-$root}
mkdir -p "$out/Images"
out=$(cd "$out" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "--- Markdown"
python3 "$root/tools/unnumbered.py" "$docx" > "$work/unnumbered.tsv"
(cd "$work" && OUT="$out" MANIFEST="$work/images.tsv" LOG="$out/convert.log" UNNUMBERED="$work/unnumbered.tsv" \
  pandoc -f docx+styles "$docx" --extract-media=. -L "$root/tools/docx2md.lua" -t plain -o /dev/null)

echo "--- Images"
python3 "$root/tools/images.py" "$work/images.tsv" "$work" "$pdf" "$out"
echo "--- Done: $(ls "$out"/Images/*.svg | wc -l | tr -d ' ') images, notes in $out/convert.log"
