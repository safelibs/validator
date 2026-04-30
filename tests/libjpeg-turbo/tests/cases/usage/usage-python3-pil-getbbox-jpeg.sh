#!/usr/bin/env bash
# @testcase: usage-python3-pil-getbbox-jpeg
# @title: Pillow Image.getbbox on JPEG
# @description: Saves a JPEG with a non-zero rectangular region on a black canvas, reopens it with Pillow and checks Image.getbbox returns the bounding box of non-zero pixels.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-getbbox-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'

# Black canvas with a bright rectangle; encode at maximum fidelity so the
# bounding box is preserved through JPEG roundtrip.
canvas = Image.new('RGB', (32, 24), (0, 0, 0))
for y in range(6, 18):
    for x in range(8, 24):
        canvas.putpixel((x, y), (200, 200, 200))
canvas.save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (32, 24)
    bbox = im.getbbox()
    assert bbox is not None, bbox
    left, top, right, bottom = bbox
    # JPEG block boundaries / 4:4:4 sampling can shift edges by a few pixels;
    # require the box to enclose the bright rectangle and stay inside the canvas.
    assert 0 <= left <= 8, bbox
    assert 0 <= top <= 6, bbox
    assert 24 <= right <= 32, bbox
    assert 18 <= bottom <= 24, bbox
    print('bbox', bbox)
PYCASE

file "$tmpdir/in.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
