#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-webp-quality-zero-roundtrip
# @title: Pillow WebP encode at quality=0 still produces a decodable image
# @description: Saves a generated RGB image via Pillow with WebP quality=0 (smallest lossy) and verifies it reloads at the original size with format WEBP.
# @timeout: 180
# @tags: usage, python3-pil, webp
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/q0.webp"
import sys
from PIL import Image
src = Image.new('RGB', (48, 36))
for y in range(36):
    for x in range(48):
        src.putpixel((x, y), (((x * 3) ^ y) & 0xff, (x * 5) & 0xff, (y * 7) & 0xff))
src.save(sys.argv[1], 'WEBP', quality=0)
PY

python3 - <<'PY' "$tmpdir/q0.webp"
import sys, os
from PIL import Image
size = os.path.getsize(sys.argv[1])
assert size > 0, size
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (48, 36), im.size
print('ok')
PY
