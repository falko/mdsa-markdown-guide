#!/usr/bin/env python3
"""Lists where the pages of the Word PDF of DMN begin, for dmn-pages.lua: one
line per page, "page<TAB>part<TAB>position<TAB>first words", where part is the
clause the page belongs to (N for the notices, P for the preface, 1 to 14, A
for the annexes), position the number of words of the clause before the page,
and the first words the first eight words of the page, in lower case, without
numbers and punctuation. The build starts a new page where these words are,
so that the pages of the PDF begin where those of the Word PDF do.

Usage: pages.py DMN_1.7_SOURCE.pdf > tools/dmn-pages.txt
"""
import re
import subprocess
import sys

FOOTER = re.compile(r'Decision Model and Notation \(DMN\), v1\.7 Beta 1')


def words(text, n=8):
    return [w.lower() for w in re.findall(r'[A-Za-z]+', text)][:n]


def clause_starts(pdf):
    """Printed page on which each clause starts, from the table of contents"""
    toc = subprocess.run(['pdftotext', '-f', '6', '-l', '9', '-layout', pdf, '-'], capture_output=True, text=True).stdout
    starts = []
    for l in toc.splitlines():
        m = re.match(r'^\s*(\d{1,2})\s+\S.*?\.{3,}\s*(\d+)\s*$', l)
        if m:
            starts.append((int(m.group(2)), m.group(1)))
        elif re.match(r'^\s*ANNEXES\b.*?(\d+)\s*$', l):
            starts.append((int(re.search(r'(\d+)\s*$', l).group(1)), 'A'))
    return starts


def main():
    pdf = sys.argv[1]
    npages = int(re.search(r'Pages:\s+(\d+)', subprocess.run(['pdfinfo', pdf], capture_output=True, text=True).stdout).group(1))
    starts = clause_starts(pdf)
    offset = None
    count = {}
    for page in range(2, npages + 1):
        text = subprocess.run(['pdftotext', '-f', str(page), '-l', str(page), '-layout', pdf, '-'],
                              capture_output=True, text=True).stdout
        lines = [l.strip() for l in text.splitlines() if l.strip() and not FOOTER.search(l)]
        if not lines or 'intentionally left blank' in lines[0]:
            continue
        first = lines[0]
        if first == 'Preface':
            part = 'P'
        elif first.startswith('Copyright'):
            continue                      # the copyrights come from the template
        elif page <= 5:
            part = 'N'
        elif first == 'Table of Contents' or page < 10:
            continue
        else:
            if offset is None:
                offset = page - 1         # the page of Clause 1 is printed page 1
            printed = page - offset
            part = None
            for start, clause in starts:
                if start <= printed:
                    part = clause
            # a clause that starts on a page belongs to the page
            for l in lines:
                m = re.match(r'^(\d{1,2})\s+[A-Z]', l)
                if m and (m.group(1), printed) in [(c, s) for s, c in starts]:
                    part = m.group(1)
                    break
        # a page that starts with a figure: the first text is in the image
        # (short lines) or its caption; the figure is found by its caption
        for n, l in enumerate(lines):
            if re.match(r'^Figure\s+[0-9A-Z]+\s*[-.]\s*\d+\s*:', l):
                if n > 0 and all(len(x) < 45 for x in lines[:n]):
                    first = l
                break
            if len(l) >= 45:
                break
        w = words(first)
        position = count.get(part, 0)
        count[part] = position + len(words(' '.join(lines), None))
        if w:
            print('%d\t%s\t%d\t%s' % (page, part, position, ' '.join(w)))


if __name__ == '__main__':
    main()
