#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-tobytes-roundtrip-byte-count
# @title: Pillow TIFF tobytes equals width*height*samples for an RGB save-then-load cycle
# @description: Saves a 6x4 RGB TIFF with deterministic pixel data, reopens it, calls im.tobytes() on the reloaded image, asserts its length equals 6*4*3 = 72 bytes (no row padding for raw RGB tobytes), and asserts the reloaded tobytes is identical to the original image's tobytes byte-for-byte, confirming libtiff RGB pixel-data preservation.
# @timeout: 60
# @tags: usage, tiff, python, tobytes, roundtrip, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/rgb.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image

src = Image.new('RGB', (6, 4))
px = src.load()
for y in range(4):
    for x in range(6):
        px[x, y] = (x * 10, y * 20, (x + y) * 5)
src.save(sys.argv[1], 'TIFF')
src_bytes = src.tobytes()

with Image.open(sys.argv[1]) as im:
    im.load()
    out = im.tobytes()
assert len(out) == 6 * 4 * 3, ('len', len(out))
assert out == src_bytes, 'pixel mismatch'
print('ok tobytes len=%d' % len(out))
PY
