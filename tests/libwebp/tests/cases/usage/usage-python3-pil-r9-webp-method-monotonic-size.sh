#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-webp-method-monotonic-size
# @title: Pillow WebP method 0 vs 6 both decode round-trip
# @description: Saves the same generated RGB image with method=0 and method=6 lossy at quality=80, decodes both, and asserts both reload at the original 64x64 dimensions.
# @timeout: 180
# @tags: usage, python3-pil, webp
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import sys, os
from PIL import Image
tmp = sys.argv[1]
src = Image.new('RGB', (64, 64))
for y in range(64):
    for x in range(64):
        src.putpixel((x, y), ((x * 4) & 0xff, (y * 4) & 0xff, ((x + y) * 3) & 0xff))
p0 = os.path.join(tmp, 'm0.webp')
p6 = os.path.join(tmp, 'm6.webp')
src.save(p0, 'WEBP', quality=80, method=0)
src.save(p6, 'WEBP', quality=80, method=6)
for path in (p0, p6):
    with Image.open(path) as im:
        im.load()
        assert im.format == 'WEBP', im.format
        assert im.size == (64, 64), im.size
print('ok')
PY
