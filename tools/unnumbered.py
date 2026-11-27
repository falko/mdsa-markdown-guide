#!/usr/bin/env python3
"""Lists the headings of a Word document whose numbering is switched off
(numId 0), one per line as "level<TAB>text", in document order.

Usage: unnumbered.py DOCX
"""
import re
import sys
import zipfile

z = zipfile.ZipFile(sys.argv[1])
doc = z.read('word/document.xml').decode('utf-8')
styles = z.read('word/styles.xml').decode('utf-8')
names = {}
for m in re.finditer(r'<w:style [^>]*w:styleId="([^"]+)"[^>]*>(.*?)</w:style>', styles, re.S):
    n = re.search(r'<w:name w:val="([^"]+)"', m.group(2))
    names[m.group(1)] = n.group(1) if n else ''
for p in re.findall(r'<w:p[ >].*?</w:p>', doc, re.S):
    s = re.search(r'<w:pStyle w:val="([^"]+)"', p)
    level = s and re.match(r'(?i)heading (\d)$', names.get(s.group(1), ''))
    if not level:
        continue
    num = re.search(r'<w:numPr>.*?</w:numPr>', p, re.S)
    if num and re.search(r'w:numId w:val="0"', num.group(0)):
        text = ''.join(re.findall(r'<w:t(?: [^>]*)?>([^<]*)</w:t>', p)).strip()
        if text:
            print('%s\t%s' % (level.group(1), text))
