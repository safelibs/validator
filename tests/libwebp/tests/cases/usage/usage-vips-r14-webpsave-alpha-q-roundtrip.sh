#!/usr/bin/env bash
# @testcase: usage-vips-r14-webpsave-alpha-q-roundtrip
# @title: vips webpsave --alpha-q 50 emits a structurally valid RGBA WebP at original geometry
# @description: Encodes an RGBA PNG through vips webpsave with --alpha-q 50 and confirms the output is recognised as WebP and reloads with bands=4 (RGBA) and the original geometry, exercising the dedicated alpha-channel quality knob.
# @timeout: 180
# @tags: usage, vips, webp, alpha
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
import sys
from PIL import Image
img = Image.new('RGBA', (48, 32))
for y in range(32):
    for x in range(48):
        img.putpixel((x, y), ((x * 7) & 0xff, (y * 13) & 0xff, ((x + y) * 5) & 0xff, ((x * y) & 0xff)))
img.save(sys.argv[1], 'PNG')
PY

vips webpsave "$tmpdir/in.png" "$tmpdir/aq.webp" --alpha-q 50 --Q 75
file "$tmpdir/aq.webp" | grep -q 'Web/P'

bands=$(vipsheader -f bands "$tmpdir/aq.webp")
w=$(vipsheader -f width "$tmpdir/aq.webp")
h=$(vipsheader -f height "$tmpdir/aq.webp")
[[ "$bands" -eq 4 ]] || { echo "bands $bands" >&2; exit 1; }
[[ "$w" -eq 48 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 32 ]] || { echo "height $h" >&2; exit 1; }
