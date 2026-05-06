#!/usr/bin/env bash
# @testcase: usage-vips-r9-webp-shrink-on-load
# @title: vips webpload shrink halves dimensions
# @description: Encodes a 64x64 WebP and reloads it via vips webpload with --shrink 2, asserting the loaded image is 32x32.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 64, 64
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 4) & 0xff, (y * 4) & 0xff, ((x + y) * 2) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
vips webpload "$tmpdir/in.webp" "$tmpdir/out.png" --shrink 2

w=$(vipsheader -f width "$tmpdir/out.png")
h=$(vipsheader -f height "$tmpdir/out.png")
[[ "$w" -eq 32 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 32 ]] || { echo "height $h" >&2; exit 1; }
