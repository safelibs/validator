#!/usr/bin/env bash
# @testcase: usage-vips-r15-webpload-shrink-four-quarters-dimensions
# @title: vips webpload --shrink 4 quarters both WebP dimensions
# @description: Saves a 64x48 RGB WebP via Pillow and runs it through vips webpload --shrink 4, then asserts vipsheader reports width=16 and height=12 (each axis quartered), exercising the libwebp DCT-domain integer subsample-on-load path.
# @timeout: 180
# @tags: usage, vips, webp, shrink
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
img = Image.new('RGB', (64, 48))
for y in range(48):
    for x in range(64):
        img.putpixel((x, y), ((x * 5) & 0xff, (y * 11) & 0xff, ((x + y) * 7) & 0xff))
img.save(sys.argv[1], 'WEBP', quality=85)
PY

vips webpload "$tmpdir/in.webp" "$tmpdir/out.v" --shrink 4
w=$(vipsheader -f width "$tmpdir/out.v")
h=$(vipsheader -f height "$tmpdir/out.v")
[[ "$w" -eq 16 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 12 ]] || { echo "height $h" >&2; exit 1; }
