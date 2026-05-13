#!/usr/bin/env bash
# @testcase: usage-vips-r16-webp-roundtrip-png-dimensions-preserved
# @title: vips webpload after webpsave preserves source PPM dimensions through a PNG round-trip
# @description: Encodes a PPM to WEBP via vips webpsave, loads the WEBP back via vips webpload and writes it out as PNG, then asserts both intermediates report the original 80x60 dimensions through vipsheader's width/height fields.
# @timeout: 120
# @tags: usage, vips, webp, roundtrip
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 80, 60
data = bytes([(((x * 5) ^ (y * 3)) & 0xff)
              for y in range(h) for x in range(w * 3)])
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/mid.webp" --Q 75
file "$tmpdir/mid.webp" | grep -q 'Web/P'

vips webpload "$tmpdir/mid.webp" "$tmpdir/out.png"
file "$tmpdir/out.png" | grep -q 'PNG image data'

w_mid=$(vipsheader -f width "$tmpdir/mid.webp")
h_mid=$(vipsheader -f height "$tmpdir/mid.webp")
w_png=$(vipsheader -f width "$tmpdir/out.png")
h_png=$(vipsheader -f height "$tmpdir/out.png")

[[ "$w_mid" == "80" && "$h_mid" == "60" ]] || { printf 'mid dims %sx%s\n' "$w_mid" "$h_mid" >&2; exit 1; }
[[ "$w_png" == "80" && "$h_png" == "60" ]] || { printf 'png dims %sx%s\n' "$w_png" "$h_png" >&2; exit 1; }
