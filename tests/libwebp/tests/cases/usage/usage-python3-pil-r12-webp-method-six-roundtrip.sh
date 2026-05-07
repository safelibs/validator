#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-webp-method-six-roundtrip
# @title: Pillow WEBP save method=6 round-trips geometry and format
# @description: Saves a small RGB image as WEBP with method=6 (slowest/best compression) and reopens to confirm the file is detected as WEBP at the original dimensions, exercising the libwebp method effort knob.
# @timeout: 180
# @tags: usage, python3-pil, webp
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/m6.webp"
import sys
from PIL import Image
src = Image.new('RGB', (40, 30))
for y in range(30):
    for x in range(40):
        src.putpixel((x, y), (((x * 5) ^ (y * 7)) & 0xff, (x * 3) & 0xff, (y * 11) & 0xff))
src.save(sys.argv[1], 'WEBP', method=6, quality=80)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (40, 30), im.size
PY
