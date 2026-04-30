#!/usr/bin/env bash
# @testcase: usage-python3-pil-point-mode-1-jpeg
# @title: Pillow Image.point mode change to 1
# @description: Loads a grayscale JPEG, applies Image.point with a threshold lookup and explicit mode "1", and verifies the result is a 1-bit Pillow image with the expected size.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-point-mode-1-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'

# Grayscale gradient saved as an L-mode JPEG so the threshold has values to act on.
gradient = Image.new('L', (16, 16))
gradient.putdata([(x * 16 + y) % 256 for y in range(16) for x in range(16)])
gradient.save(source, 'JPEG', quality=100, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'L'
    assert im.size == (16, 16)
    # Image.point with a callable + explicit mode='1' switches the result to
    # a 1-bit image; this is the lookup-table-with-mode-change path.
    bw = im.point(lambda v: 255 if v >= 128 else 0, mode='1')
    assert bw.mode == '1', bw.mode
    assert bw.size == (16, 16)
    pixels = list(bw.getdata())
    assert set(pixels).issubset({0, 255}), set(pixels)
    assert any(p == 0 for p in pixels), 'expected at least one 0 pixel'
    assert any(p == 255 for p in pixels), 'expected at least one 255 pixel'
    print('point-mode-1', bw.mode, bw.size)
PYCASE

file "$tmpdir/in.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
