#!/usr/bin/env bash
# @testcase: usage-vips-r19-webp-roundtrip-preserves-pixel-count
# @title: vips webpsave then webpload preserves total pixel count (width*height) for a still
# @description: Encodes a 40x30 PPM to WEBP via vips webpsave, then reads it back via vips webpload to a new PNG, and asserts vipsheader reports the PNG has 40*30=1200 pixels via width*height, locking in lossy-roundtrip dimension preservation.
# @timeout: 120
# @tags: usage, vips, webp, roundtrip, r19
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 40, 30
data = bytes([(((x * 5) + (y * 11)) & 0xff)
              for y in range(h) for x in range(w * 3)])
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/out.webp" --Q 80
vips copy "$tmpdir/out.webp" "$tmpdir/out.png"

w_out=$(vipsheader -f width "$tmpdir/out.png")
h_out=$(vipsheader -f height "$tmpdir/out.png")
pixels=$(( w_out * h_out ))
[[ "$pixels" == "1200" ]] || { printf 'expected 1200 pixels, got %s (%sx%s)\n' "$pixels" "$w_out" "$h_out" >&2; exit 1; }
