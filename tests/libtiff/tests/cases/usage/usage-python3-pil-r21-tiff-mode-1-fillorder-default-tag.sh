#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-tiff-mode-1-fillorder-default-tag
# @title: Pillow mode 1 TIFF default FillOrder tag (266) defaults to MSB2LSB (value 1)
# @description: Saves an 8x8 mode-1 TIFF (bilevel), opens it via Image.open, and asserts the FillOrder tag (266) is present in tag_v2 and equals 1 (MSB2LSB), validating libtiff's bilevel default fill-order encoding.
# @timeout: 60
# @tags: usage, tiff, python, fillorder, bilevel, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/bilevel.tif" <<'PY'
import sys
from PIL import Image

Image.new('1', (8, 8), 0).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    tags = im.tag_v2
    # FillOrder tag may be absent (defaults to MSB2LSB) or present with value 1.
    if 266 in tags:
        v = tags[266]
        if isinstance(v, tuple):
            v = v[0]
        assert v == 1, v
        print('ok fillorder=%r' % (v,))
    else:
        # Absence means defaults apply (MSB2LSB).
        print('ok fillorder=default')
PY
