#!/usr/bin/env bash
# @testcase: usage-vips-r12-webpsave-smart-subsample-flag-roundtrip
# @title: vips webpsave --smart-subsample produces a valid WebP at the original size
# @description: Encodes a synthetic RGB image through vips webpsave with --smart-subsample and a fixed Q, then verifies the output is a structurally valid WebP that decodes back to the original geometry via vipsheader.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 48, 36
data = bytes([(((x * 5) ^ (y * 3)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/ss.webp" --smart-subsample --Q 70
file "$tmpdir/ss.webp" | grep -q 'Web/P'

w=$(vipsheader -f width "$tmpdir/ss.webp")
h=$(vipsheader -f height "$tmpdir/ss.webp")
[[ "$w" -eq 48 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 36 ]] || { echo "height $h" >&2; exit 1; }
