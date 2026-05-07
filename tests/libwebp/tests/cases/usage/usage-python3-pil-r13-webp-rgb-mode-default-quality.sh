#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-webp-rgb-mode-default-quality
# @title: Pillow WEBP default-quality save reloads as a same-size RGB image
# @description: Saves a 32x24 RGB Pillow image as WEBP without any quality= argument and confirms the reload preserves size, format=WEBP, and the file's RIFF/WEBP magic header bytes.
# @timeout: 180
# @tags: usage, python3-pil, webp
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/d.webp"
import sys
from PIL import Image
src = Image.new('RGB', (32, 24))
for y in range(24):
    for x in range(32):
        src.putpixel((x, y), ((x * 7) & 0xff, (y * 11) & 0xff, ((x ^ y) * 5) & 0xff))
src.save(sys.argv[1], 'WEBP')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (32, 24), im.size

# Verify RIFF .... WEBP magic.
data = open(sys.argv[1], 'rb').read(16)
assert data[:4] == b'RIFF', data[:4]
assert data[8:12] == b'WEBP', data[8:12]
PY
