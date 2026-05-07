#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-webp-method-zero-vs-six-monotonic-size
# @title: Pillow WEBP save method=6 yields a no-larger file than method=0 at constant quality
# @description: Saves the same RGB image as WEBP via Pillow twice — once with method=0 (fastest) and once with method=6 (best) at quality=80 — and asserts the method=6 file size is no larger than method=0, exercising the libwebp method effort knob's monotonic size effect through Pillow.
# @timeout: 180
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
src = Image.new('RGB', (96, 64))
for y in range(64):
    for x in range(96):
        src.putpixel((x, y), ((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 7) & 0xff))

src.save(base / 'm0.webp', 'WEBP', quality=80, method=0)
src.save(base / 'm6.webp', 'WEBP', quality=80, method=6)

s0 = (base / 'm0.webp').stat().st_size
s6 = (base / 'm6.webp').stat().st_size
assert s0 > 0 and s6 > 0
assert s6 <= s0, f'expected method=6 ({s6}) <= method=0 ({s0})'
PY
