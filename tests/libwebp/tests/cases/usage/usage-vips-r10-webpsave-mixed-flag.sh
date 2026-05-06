#!/usr/bin/env bash
# @testcase: usage-vips-r10-webpsave-mixed-flag
# @title: vips webpsave with mixed=true on animation produces a valid WebP
# @description: Encodes a 3-frame WebP via Pillow, reloads via vips webpload --n -1, then re-encodes through vips webpsave --mixed and asserts the output reloads at the original base dimensions.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/anim.webp"
import sys
from PIL import Image
frames = [Image.new('RGBA', (32, 24), (60 + 60 * i, 140, 240 - 60 * i, 255)) for i in range(3)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=80, loop=0, lossless=True)
PY

vips webpload "$tmpdir/anim.webp" "$tmpdir/strip.v" --n -1
vips webpsave "$tmpdir/strip.v" "$tmpdir/out.webp" --mixed --Q 70

file "$tmpdir/out.webp" | grep -q 'Web/P'
vips webpload "$tmpdir/out.webp" "$tmpdir/first.png"
w=$(vipsheader -f width "$tmpdir/first.png")
h=$(vipsheader -f height "$tmpdir/first.png")
[[ "$w" -eq 32 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 24 ]] || { echo "height $h" >&2; exit 1; }
