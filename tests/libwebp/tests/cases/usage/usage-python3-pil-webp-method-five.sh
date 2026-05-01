#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-method-five
# @title: Pillow WebP save method=5
# @description: Saves an RGB image to WebP with quality=80 and method=5 via Pillow and confirms the output reloads as a WebP at the source dimensions with format=='WEBP'.
# @timeout: 180
# @tags: usage, webp, python, method
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-method-five"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmp = Path(sys.argv[2])

im = Image.new('RGB', (12, 9))
for y in range(9):
    for x in range(12):
        im.putpixel((x, y), ((x * 19) % 256, (y * 29) % 256, ((x * y) * 7) % 256))

out = tmp / 'm5.webp'
im.save(out, 'WEBP', quality=80, method=5)

assert out.is_file()
assert out.stat().st_size > 0
hdr = out.read_bytes()[:12]
assert hdr[:4] == b'RIFF' and hdr[8:12] == b'WEBP'

with Image.open(out) as r:
    r.load()
    assert r.format == 'WEBP', r.format
    assert r.size == (12, 9), r.size
    print('method-5 size', r.size)
PY
