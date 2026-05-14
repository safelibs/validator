#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-webp-save-exact-true-preserves-alpha-zero-rgb
# @title: Pillow WEBP save with exact=True preserves RGB under fully-transparent pixels
# @description: Saves an RGBA image whose alpha channel is zero everywhere but with distinctive RGB values, using Pillow's WEBP encoder with exact=True and lossless=True, then asserts the round-tripped pixel keeps the exact RGB triple at transparent regions.
# @timeout: 60
# @tags: usage, python3-pil, webp, exact, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.webp" <<'PY'
import sys
from PIL import Image

img = Image.new('RGBA', (32, 32), (10, 20, 30, 0))
img.save(sys.argv[1], 'WEBP', lossless=True, exact=True)

with Image.open(sys.argv[1]) as out:
    out.load()
    assert out.format == 'WEBP', out.format
    assert out.mode == 'RGBA', out.mode
    px = out.getpixel((5, 7))
    assert px == (10, 20, 30, 0), px
PY
