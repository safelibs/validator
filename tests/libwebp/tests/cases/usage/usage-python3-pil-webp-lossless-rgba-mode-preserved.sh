#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-lossless-rgba-mode-preserved
# @title: Pillow WebP lossless RGBA mode preserved on reopen
# @description: Saves an RGBA image as lossless WebP via Pillow and verifies the reopened image has mode RGBA with intact alpha channel extrema.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-lossless-rgba-mode-preserved"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

src = Image.new('RGBA', (8, 4))
for y in range(4):
    for x in range(8):
        src.putpixel((x, y), ((x * 31) % 256, (y * 53) % 256, ((x ^ y) * 17) % 256, (x * 32 + y * 16) % 256))

out = tmpdir / 'lossless.webp'
src.save(out, 'WEBP', lossless=True, exact=True, method=6)

with Image.open(out) as reopened:
    reopened.load()
    assert reopened.format == 'WEBP'
    assert reopened.mode == 'RGBA', reopened.mode
    assert reopened.size == (8, 4)
    alpha = reopened.split()[3]
    extrema = alpha.getextrema()

print('alpha extrema', extrema)
assert extrema[0] == 0
assert extrema[1] > 0
PYCASE
