#!/usr/bin/env python3
"""Writes the images listed by docx2md.lua as SVG files.

Usage: images.py MANIFEST MEDIA_DIR REFERENCE_PDF OUT_DIR

Each manifest line is tab-separated: kind, source, destination, and for
  media: width and height as shown in the Word document (e.g. "4.6in")
  crop:  mode ("in" or "after") and a text to find the figure in the PDF

- media: an image from the Word document. SVG images are copied with the size
  they have in the document; PNG and JPEG images are embedded in an SVG file,
  since the build accepts SVG only.
- crop: a figure that Word draws with a table or text box (boxed expressions).
  It is cut from the reference PDF as vector graphics: the region between the
  text it starts with (mode "in") or follows (mode "after") and its caption.

Needs pdftotext, pdftoppm and pdftocairo (poppler).
"""

import base64
import os
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET


def image_size(data):
    if data[:8] == b'\x89PNG\r\n\x1a\n':
        w, h = struct.unpack('>II', data[16:24])
        return w, h, 'image/png'
    if data[:2] == b'\xff\xd8':
        i = 2
        while i < len(data):
            if data[i] != 0xFF:
                i += 1
                continue
            marker = data[i + 1]
            if marker in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
                h, w = struct.unpack('>HH', data[i + 5:i + 9])
                return w, h, 'image/jpeg'
            if marker in (0xD8, 0x01) or 0xD0 <= marker <= 0xD7:
                i += 2
                continue
            seg = struct.unpack('>H', data[i + 2:i + 4])[0]
            i += 2 + seg
    raise ValueError('unknown image format')


def inches(s):
    m = re.match(r'^([\d.]+)in$', s or '')
    return float(m.group(1)) if m else None


def fmt(x):
    return ('%.3f' % x).rstrip('0').rstrip('.')


def write_media(src, dest, width, height):
    data = open(src, 'rb').read()
    w_in, h_in = inches(width), inches(height)
    if src.lower().endswith('.svg'):
        ET.register_namespace('', 'http://www.w3.org/2000/svg')
        ET.register_namespace('xlink', 'http://www.w3.org/1999/xlink')
        tree = ET.ElementTree(ET.fromstring(data))
        root = tree.getroot()
        if 'viewBox' not in root.attrib:
            vw = re.sub(r'[a-z]+$', '', root.get('width', '100'))
            vh = re.sub(r'[a-z]+$', '', root.get('height', '100'))
            root.set('viewBox', '0 0 %s %s' % (vw, vh))
        if w_in and h_in:
            root.set('width', fmt(w_in) + 'in')
            root.set('height', fmt(h_in) + 'in')
        tree.write(dest, encoding='utf-8', xml_declaration=True)
        return
    pw, ph, mime = image_size(data)
    if not (w_in and h_in):
        w_in, h_in = pw / 96, ph / 96
    b64 = base64.b64encode(data).decode('ascii')
    lines = [b64[i:i + 76] for i in range(0, len(b64), 76)]
    with open(dest, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
                'width="%sin" height="%sin" viewBox="0 0 %d %d">\n' % (fmt(w_in), fmt(h_in), pw, ph))
        f.write('<image width="%d" height="%d" preserveAspectRatio="none" xlink:href="data:%s;base64,\n%s"/>\n'
                % (pw, ph, mime, '\n'.join(lines)))
        f.write('</svg>\n')


# --- Figures cut from the reference PDF ------------------------------------

_bbox_cache = {}


def page_lines(pdf, page):
    if page not in _bbox_cache:
        out = subprocess.run(['pdftotext', '-f', str(page), '-l', str(page), '-bbox-layout', pdf, '-'],
                             capture_output=True, text=True, check=True).stdout
        out = re.sub(r'<!DOCTYPE[^>]*>', '', out)
        root = ET.fromstring(out)
        ns = {'x': 'http://www.w3.org/1999/xhtml'}
        lines = []
        for line in root.iter('{http://www.w3.org/1999/xhtml}line'):
            words = [w.text or '' for w in line.findall('x:word', ns)]
            lines.append({
                'text': ' '.join(words),
                'x0': float(line.get('xMin')), 'y0': float(line.get('yMin')),
                'x1': float(line.get('xMax')), 'y1': float(line.get('yMax')),
            })
        lines.sort(key=lambda l: (l['y0'], l['x0']))
        _bbox_cache[page] = lines
    return _bbox_cache[page]


def norm(s):
    s = s.replace('‑', '-').replace('–', '-').replace('’', "'").replace('‘', "'")
    s = s.replace('“', '"').replace('”', '"').replace('…', '...')
    return re.sub(r'\s+', ' ', s).strip()


def find_caption(pdf, npages, label, caption):
    """Page and line of the caption 'Figure 10-4: ...'"""
    num = label.split(' ', 1)[1]
    a, b = num.split('-')
    pat = re.compile(r'^Figure\s*%s\s*-\s*%s\s*:\s*(.*)$' % (re.escape(a), re.escape(b)))
    words = norm(caption).split(' ')[:2]
    for page in range(1, npages + 1):
        for line in page_lines(pdf, page):
            m = pat.match(norm(line['text']))
            if m and m.group(1).split(' ')[:2] == words[:len(m.group(1).split(' ')[:2])] and m.group(1):
                return page, line
    raise LookupError(label)


def dark_rows(pdf, page, x0, y0, x1, y1, dpi=144):
    """Rows (in points) of the region that contain dark pixels, and the
    horizontal extent of the dark pixels."""
    scale = dpi / 72.0
    X, Y = int(x0 * scale), int(y0 * scale)
    W, H = int((x1 - x0) * scale), int((y1 - y0) * scale)
    data = subprocess.run(['pdftoppm', '-f', str(page), '-l', str(page), '-r', str(dpi), '-gray',
                           '-x', str(X), '-y', str(Y), '-W', str(W), '-H', str(H), pdf],
                          capture_output=True, check=True).stdout
    # PGM: P5\n<w> <h>\n<max>\n<data>
    parts = data.split(b'\n', 3)
    w, h = map(int, parts[1].split())
    pix = parts[3]
    rows = []
    xmin, xmax = None, None
    for r in range(h):
        row = pix[r * w:(r + 1) * w]
        dark = [i for i, v in enumerate(row) if v < 200]
        if dark:
            rows.append(r)
            xmin = dark[0] if xmin is None else min(xmin, dark[0])
            xmax = dark[-1] if xmax is None else max(xmax, dark[-1])
    to_pt = lambda v: v / scale
    return [Y / scale + to_pt(r) for r in rows], (None if xmin is None else (X / scale + to_pt(xmin), X / scale + to_pt(xmax)))


def write_crop(pdf, npages, label, dest, mode, caption, text):
    page, cap = find_caption(pdf, npages, label, caption)
    lines = [l for l in page_lines(pdf, page) if l['y1'] <= cap['y0'] + 0.5]
    left, right = 36.0, 560.0
    top = 40.0
    key = norm(text)
    if mode == 'after':
        tail = key[-25:]
        cands = [l for l in lines if norm(l['text']).endswith(tail) or tail.endswith(norm(l['text'])[-25:])]
        if cands:
            top = cands[-1]['y1'] + 1
    else:
        head = key[:25]
        cands = [l for l in lines if head and (norm(l['text']).startswith(head) or head.startswith(norm(l['text'])))]
        if cands:
            # the nearest match above the caption, then upwards while the
            # region is connected (table borders)
            start = cands[-1]['y0'] - 1
            rows, _ = dark_rows(pdf, page, left, top, right, cap['y0'] - 1)
            rows = [r for r in rows if r <= start]
            t = start
            for r in reversed(rows):
                if t - r > 3.5:
                    break
                t = r
            top = t
        else:
            # no text to find: everything below the last text line above the
            # figure that ends a sentence
            print('  %s: "%s" not found, using the region above the caption' % (label, head), file=sys.stderr)
    rows, xr = dark_rows(pdf, page, left, top, right, cap['y0'] - 1)
    if not rows:
        raise LookupError('empty region for ' + label)
    y0, y1 = int(rows[0] - 2), int(rows[-1] + 3)
    x0, x1 = int(xr[0] - 2), int(xr[1] + 3)
    subprocess.run(['pdftocairo', '-svg', '-f', str(page), '-l', str(page),
                    '-x', str(x0), '-y', str(y0), '-W', str(x1 - x0), '-H', str(y1 - y0),
                    pdf, dest], check=True)
    print('  %s: page %d, %.0fx%.0f pt' % (label, page, x1 - x0, y1 - y0), file=sys.stderr)


def main():
    manifest, media, pdf, out = sys.argv[1:5]
    npages = int(re.search(r'Pages:\s+(\d+)', subprocess.run(['pdfinfo', pdf], capture_output=True, text=True).stdout).group(1))
    written = set()
    for line in open(manifest, encoding='utf-8'):
        f = line.rstrip('\n').split('\t')
        if len(f) < 6:
            continue
        kind, src, dest = f[0], f[1], f[2]
        path = os.path.join(out, dest)
        written.add(os.path.normpath(path))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if kind == 'media':
            write_media(os.path.join(media, src), path, f[3], f[4])
        elif kind == 'crop':
            write_crop(pdf, npages, src, path, f[3], f[4], f[5])
    # images of an earlier conversion that are no longer used
    images = os.path.join(out, 'Images')
    for name in sorted(os.listdir(images)):
        path = os.path.normpath(os.path.join(images, name))
        if name.endswith('.svg') and path not in written:
            print('  removing unused ' + name, file=sys.stderr)
            os.remove(path)


if __name__ == '__main__':
    main()
