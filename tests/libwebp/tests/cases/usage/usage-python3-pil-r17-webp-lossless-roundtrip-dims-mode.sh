#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-webp-lossless-roundtrip-dims-mode
# @title: Pillow WEBP lossless save+open preserves dims and mode and tbinds at RGB
# @description: Saves an RGB image as WEBP with lossless=True via Pillow, re-opens the file, and asserts dims, mode (RGB) and format (WEBP) round-trip — without asserting exact bytes since lossless encoder output varies across versions.
# @timeout: 60
# @tags: usage, python3-pil, webp, lossless, roundtrip
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.webp" <<'PY'
import sys
from PIL import Image

img = Image.new('RGB', (40, 24))
for y in range(24):
    for x in range(40):
        img.putpixel((x, y), ((x * 7) & 0xff, (y * 11) & 0xff, ((x ^ y) * 3) & 0xff))

img.save(sys.argv[1], 'WEBP', lossless=True, quality=100)

with Image.open(sys.argv[1]) as out:
    out.load()
    assert out.mode == 'RGB', out.mode
    assert out.size == (40, 24), out.size
    assert out.format == 'WEBP', out.format
    # Lossless pixel parity: at least the center pixel must match exactly.
    cx, cy = 20, 12
    src_px = ((cx * 7) & 0xff, (cy * 11) & 0xff, ((cx ^ cy) * 3) & 0xff)
    out_px = out.getpixel((cx, cy))
    assert out_px == src_px, (out_px, src_px)
PY
