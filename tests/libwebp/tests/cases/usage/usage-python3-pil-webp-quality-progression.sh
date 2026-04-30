#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-quality-progression
# @title: Pillow WebP quality progression monotonic
# @description: Saves the same RGB image at Pillow WebP quality 20, 50, 90 and asserts file sizes are strictly monotonic increasing.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-quality-progression"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import random
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

random.seed(0xBEEF)
img = Image.new('RGB', (48, 32))
for y in range(32):
    for x in range(48):
        img.putpixel((x, y), (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)))

sizes = {}
for q in (20, 50, 90):
    out = tmpdir / f'q{q}.webp'
    img.save(out, 'WEBP', quality=q, method=4)
    sizes[q] = out.stat().st_size
    with Image.open(out) as im:
        im.load()
        assert im.format == 'WEBP'
        assert im.size == (48, 32)

print(sizes)
assert sizes[20] < sizes[50] < sizes[90], sizes
PYCASE
