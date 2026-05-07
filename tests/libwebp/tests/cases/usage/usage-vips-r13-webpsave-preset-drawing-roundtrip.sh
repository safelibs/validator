#!/usr/bin/env bash
# @testcase: usage-vips-r13-webpsave-preset-drawing-roundtrip
# @title: vips webpsave --preset drawing produces a valid WebP at original geometry
# @description: Encodes a synthetic RGB image through vips webpsave --preset drawing at a fixed Q and verifies the output is recognised as WebP and reloads at the input dimensions, exercising the preset selector path.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 64, 48
data = bytes([(((x * 5) + (y * 11)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/d.webp" --preset drawing --Q 75
file "$tmpdir/d.webp" | grep -q 'Web/P'

w=$(vipsheader -f width "$tmpdir/d.webp")
h=$(vipsheader -f height "$tmpdir/d.webp")
[[ "$w" -eq 64 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 48 ]] || { echo "height $h" >&2; exit 1; }
