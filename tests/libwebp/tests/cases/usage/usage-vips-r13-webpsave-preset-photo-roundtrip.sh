#!/usr/bin/env bash
# @testcase: usage-vips-r13-webpsave-preset-photo-roundtrip
# @title: vips webpsave --preset photo produces a valid WebP at original geometry
# @description: Encodes a synthetic RGB image through vips webpsave --preset photo at a fixed Q and verifies the output is recognised as WebP and reloads at the input dimensions via vipsheader, exercising the photo preset's encoder configuration.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 56, 40
data = bytes([(((x * 7) ^ (y * 13)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/p.webp" --preset photo --Q 70
file "$tmpdir/p.webp" | grep -q 'Web/P'

w=$(vipsheader -f width "$tmpdir/p.webp")
h=$(vipsheader -f height "$tmpdir/p.webp")
[[ "$w" -eq 56 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 40 ]] || { echo "height $h" >&2; exit 1; }
