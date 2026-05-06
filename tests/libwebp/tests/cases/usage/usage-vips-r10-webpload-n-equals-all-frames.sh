#!/usr/bin/env bash
# @testcase: usage-vips-r10-webpload-n-equals-all-frames
# @title: vips webpload n=-1 stacks all animation frames vertically
# @description: Builds a 4-frame animated WebP via Pillow then loads it through vips webpload with n=-1, asserting the resulting strip height equals base_height * 4.
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
frames = [Image.new('RGBA', (20, 14), (40 + 50 * i, 80, 200 - 30 * i, 255)) for i in range(4)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=80, loop=0, lossless=True)
PY

vips webpload "$tmpdir/anim.webp" "$tmpdir/strip.png" --n -1
w=$(vipsheader -f width "$tmpdir/strip.png")
h=$(vipsheader -f height "$tmpdir/strip.png")
[[ "$w" -eq 20 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 56 ]] || { echo "height $h" >&2; exit 1; }
