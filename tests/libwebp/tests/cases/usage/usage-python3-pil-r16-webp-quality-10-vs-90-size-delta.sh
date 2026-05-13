#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-webp-quality-10-vs-90-size-delta
# @title: Pillow WEBP quality=10 yields a smaller file than quality=90 on the same source
# @description: Encodes the same RGB image as WEBP via Pillow at quality=10 and quality=90 and asserts the q=10 file is strictly smaller than q=90, exercising the lossy quality knob's size response through Pillow's libwebp binding.
# @timeout: 120
# @tags: usage, python3-pil, webp, quality
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
        img.putpixel((x, y), ((x * 17) & 0xff, (y * 23) & 0xff, ((x ^ y) * 5) & 0xff))

img.save(base / 'q10.webp', 'WEBP', quality=10)
img.save(base / 'q90.webp', 'WEBP', quality=90)

s10 = (base / 'q10.webp').stat().st_size
s90 = (base / 'q90.webp').stat().st_size
assert s10 > 0 and s90 > 0
assert s10 < s90, f'expected q=10 ({s10}) < q=90 ({s90})'
PY
