#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-method-zero-vs-six
# @title: Pillow WebP method=0 fast vs method=6 best
# @description: Saves the same RGB image with Pillow at WebP method=0 and method=6, verifying both reload as WEBP with matching dimensions.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-method-zero-vs-six"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

base = Image.new('RGB', (12, 8))
for y in range(8):
    for x in range(12):
        base.putpixel((x, y), ((x * 17) % 256, (y * 23) % 256, ((x + y) * 11) % 256))

fast = tmpdir / 'fast.webp'
best = tmpdir / 'best.webp'
base.save(fast, 'WEBP', quality=60, method=0)
base.save(best, 'WEBP', quality=60, method=6)

for path in (fast, best):
    with Image.open(path) as im:
        im.load()
        assert im.format == 'WEBP', (path, im.format)
        assert im.size == (12, 8), (path, im.size)

print('fast', fast.stat().st_size, 'best', best.stat().st_size)
assert fast.stat().st_size > 0
assert best.stat().st_size > 0
PYCASE
