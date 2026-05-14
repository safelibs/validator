#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-webp-method-six-vs-zero-size-monotonic
# @title: Pillow WEBP method=6 produces a file no larger than method=0 at fixed quality
# @description: Encodes the same RGB image through Pillow as WEBP at quality=75 with method=0 and method=6, and asserts the method=6 output is no larger than method=0, exercising libwebp's method effort knob through Pillow.
# @timeout: 120
# @tags: usage, python3-pil, webp, method
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
img = Image.new('RGB', (128, 96))
for y in range(96):
    for x in range(128):
        img.putpixel((x, y), ((x * 13) & 0xff, (y * 17) & 0xff, ((x + y) * 5) & 0xff))

img.save(base / 'm0.webp', 'WEBP', quality=75, method=0)
img.save(base / 'm6.webp', 'WEBP', quality=75, method=6)

s0 = (base / 'm0.webp').stat().st_size
s6 = (base / 'm6.webp').stat().st_size
assert s0 > 0 and s6 > 0
assert s6 <= s0, f'expected method=6 ({s6}) <= method=0 ({s0})'
PY
