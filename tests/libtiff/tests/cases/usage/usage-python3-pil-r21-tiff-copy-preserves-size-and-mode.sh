#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-copy-preserves-size-and-mode
# @title: Pillow Image.copy on an opened TIFF preserves size, mode, and pixel value
# @description: Saves a 6x6 mode-L TIFF filled with 77, opens it, calls .copy() and asserts the returned image has identical size, mode, and getpixel((0,0)) value as the original, validating libtiff decode plus Pillow's image clone path.
# @timeout: 60
# @tags: usage, tiff, python, copy, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/cp.tif" <<'PY'
import sys
from PIL import Image

Image.new('L', (6, 6), 77).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as r:
    r.load()
    c = r.copy()
    assert c.size == r.size, (c.size, r.size)
    assert c.mode == r.mode, (c.mode, r.mode)
    assert c.getpixel((0, 0)) == r.getpixel((0, 0)) == 77
    print('ok copy size=%r mode=%s pixel=%d' % (c.size, c.mode, c.getpixel((0, 0))))
PY
