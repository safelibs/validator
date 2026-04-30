#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-exact-lossless-rgba
# @title: Pillow WebP exact lossless RGBA roundtrip
# @description: Saves an RGBA Pillow image to WebP with exact=True and lossless=True, then verifies pixel-exact roundtrip.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-exact-lossless-rgba"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

src = Image.new('RGBA', (4, 3))
pixels = [
    (255, 0, 0, 0), (0, 255, 0, 0), (0, 0, 255, 0), (255, 255, 0, 0),
    (255, 0, 255, 64), (0, 255, 255, 64), (40, 40, 40, 128), (220, 220, 220, 128),
    (100, 20, 30, 200), (20, 100, 30, 200), (20, 30, 100, 255), (200, 120, 20, 255),
]
src.putdata(pixels)

out = tmpdir / 'exact.webp'
src.save(out, 'WEBP', lossless=True, exact=True)

with Image.open(out) as reopened:
    reopened.load()
    assert reopened.format == 'WEBP'
    assert reopened.mode == 'RGBA'
    assert reopened.size == (4, 3)
    got = list(reopened.getdata())

assert got == pixels, f"pixel mismatch: {got}"
print('exact-rgba', len(got))
PYCASE
