#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-method-one-save
# @title: Pillow WebP method one save
# @description: Saves a synthetic RGB image to WebP through Pillow with encoder method=1 (fast path) and verifies the file is a valid WebP that reopens with the expected mode and size.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-method-one-save"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

base = Image.new('RGB', (9, 7))
for y in range(7):
    for x in range(9):
        base.putpixel((x, y), ((x * 17) % 256, (y * 23) % 256, ((x + y) * 13) % 256))

out = tmpdir / 'method1.webp'
base.save(out, 'WEBP', quality=80, method=1)

assert out.is_file()
size = out.stat().st_size
assert size > 0, size

with Image.open(out) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (9, 7), im.size
    assert im.mode in ('RGB', 'RGBA'), im.mode

# Verify file magic via the RIFF/WEBP header bytes.
header = out.read_bytes()[:12]
assert header[:4] == b'RIFF', header[:4]
assert header[8:12] == b'WEBP', header[8:12]
print('method1 size', size)
PYCASE
