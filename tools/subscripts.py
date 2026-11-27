#!/usr/bin/env python3
"""Copies a Word document, marking as subscripts the runs that the document
sets as subscripts only by a smaller font size (e.g. e1 in "e1 >= e2", the 1
at 5pt after the e at 9pt), so that the conversion sees them as subscripts.

Usage: subscripts.py IN.docx OUT.docx

A run is marked if its font is at most 2/3 of the size of the run before it,
that run ends with a letter, and its text is one to three characters that all
have a Unicode subscript (digits and some lowercase letters).
"""
import re
import sys
import zipfile

SUBSCRIPTABLE = set('0123456789aehijklmnoprstuvx')
RUN = re.compile(r'<w:r(?: [^>]*)?>(?:(?!</w:r>).)*</w:r>', re.S)


def size(run):
    m = re.search(r'<w:sz w:val="(\d+)"', run)
    return int(m.group(1)) if m else None


def text(run):
    return ''.join(re.findall(r'<w:t(?: [^>]*)?>([^<]*)</w:t>', run))


def mark(xml):
    runs = list(RUN.finditer(xml))
    out, pos, count = [], 0, 0
    for prev, run in zip([None] + runs, runs):
        r = run.group(0)
        if prev is not None and 'w:vertAlign' not in r:
            sp, sr, tp, tr = size(prev.group(0)), size(r), text(prev.group(0)), text(r)
            if (sp and sr and sr * 3 <= sp * 2 and re.search(r'[A-Za-z]$', tp)
                    and 1 <= len(tr) <= 3 and set(tr) <= SUBSCRIPTABLE and tr not in ('th', 'st', 'nd', 'rd')):
                r = r.replace('</w:rPr>', '<w:vertAlign w:val="subscript"/></w:rPr>', 1)
                count += 1
        out.append(xml[pos:run.start()])
        out.append(r)
        pos = run.end()
    out.append(xml[pos:])
    return ''.join(out), count


def main():
    src, dest = sys.argv[1:3]
    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == 'word/document.xml':
                xml, count = mark(data.decode('utf-8'))
                data = xml.encode('utf-8')
                print('  %d runs marked as subscripts' % count, file=sys.stderr)
            zout.writestr(item, data)


if __name__ == '__main__':
    main()
