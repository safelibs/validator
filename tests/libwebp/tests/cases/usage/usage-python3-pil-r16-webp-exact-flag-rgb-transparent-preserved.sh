#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-webp-exact-flag-rgb-transparent-preserved
# @title: Pillow WEBP exact=True lossless round-trip preserves RGB values under a fully-transparent alpha pixel
# @description: Crafts an RGBA image with a colored pixel whose alpha is zero, saves it via Pillow as lossless WEBP with exact=True, reloads it, and asserts the underlying RGB channels of the transparent pixel are preserved exactly (libwebp exact-flag semantics).
# @timeout: 120
# @tags: usage, python3-pil, webp, lossless, alpha
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.webp" <<'PY'
import sys
from PIL import Image

img = Image.new('RGBA', (16, 16), (10, 20, 30, 255))
# Fully transparent pixel with distinct RGB values.
img.putpixel((4, 5), (123, 45, 67, 0))
img.save(sys.argv[1], 'WEBP', lossless=True, exact=True, quality=100)

with Image.open(sys.argv[1]) as out:
    out.load()
    assert out.mode == 'RGBA', out.mode
    px = out.getpixel((4, 5))
    assert px == (123, 45, 67, 0), px
PY
