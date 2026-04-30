#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-lossless-method-zero
# @title: Pillow WebP lossless save with method=0 (fast)
# @description: Saves an RGB image as lossless WebP through Pillow with method=0 (fastest) and verifies the file decodes back as a WEBP image with the original dimensions and pixel.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-lossless-method-zero"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

base = Image.new('RGB', (9, 5))
for y in range(5):
    for x in range(9):
        base.putpixel((x, y), ((x * 19) % 256, (y * 31) % 256, ((x + y) * 13) % 256))

out = tmpdir / 'fast-lossless.webp'
base.save(out, 'WEBP', lossless=True, method=0)
assert out.stat().st_size > 0

with Image.open(out) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (9, 5), im.size
    # Lossless must be exact at the chosen method.
    assert im.convert('RGB').getpixel((4, 2)) == base.getpixel((4, 2))
    print('lossless-method-zero', im.size, out.stat().st_size)

# Verify the file magic ourselves.
data = out.read_bytes()
assert data[:4] == b'RIFF' and data[8:12] == b'WEBP', data[:12]
PYCASE
