#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-tobytes-getdata-equal-length
# @title: Pillow TIFF image tobytes length equals width*height for L-mode
# @description: Saves and reopens a 5x6 mode-L TIFF, calls .tobytes() and asserts the length equals 5*6 (30), and calls list(im.getdata()) and asserts its length is also 30, confirming libtiff decodes the strip data back to a contiguous one-byte-per-pixel buffer for grayscale.
# @timeout: 60
# @tags: usage, tiff, python, tobytes, getdata, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/gray56.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

Image.new('L', (5, 6), 42).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as r:
    r.load()
    raw = r.tobytes()
    assert len(raw) == 5 * 6, len(raw)
    data = list(r.getdata())
    assert len(data) == 5 * 6, len(data)
    print('ok len=%d' % len(raw))
PY
