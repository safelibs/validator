#!/usr/bin/env bash
# @testcase: usage-vips-r11-webpload-page-zero-explicit
# @title: vips webpload --page 0 selects the first frame of an animated WebP
# @description: Builds a 4-frame animated WebP via Pillow then loads it through vips webpload with an explicit --page 0, asserting the output PNG matches the base frame geometry exactly (no vertical strip stacking).
# @timeout: 180
# @tags: usage, vips, webp, animation
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/anim.webp"
import sys
from PIL import Image
frames = [Image.new('RGBA', (24, 18), (40 + 50 * i, 80, 200 - 30 * i, 255)) for i in range(4)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=80, loop=0, lossless=True)
PY

vips webpload "$tmpdir/anim.webp" "$tmpdir/page0.png" --page 0
w=$(vipsheader -f width "$tmpdir/page0.png")
h=$(vipsheader -f height "$tmpdir/page0.png")
[[ "$w" -eq 24 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 18 ]] || { echo "height $h" >&2; exit 1; }
