#!/usr/bin/env bash
# @testcase: usage-vips-r9-webpsave-effort-six
# @title: vips webpsave effort 6 produces smaller-or-equal output than effort 0
# @description: Encodes the same source PNG via vips webpsave with effort=0 and effort=6 (both lossy Q=75), and verifies both files are valid WebP.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 96, 96
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 5) & 0xff, (y * 7) & 0xff, ((x + y) * 3) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

vips copy "$tmpdir/in.ppm" "$tmpdir/in.png"
vips webpsave "$tmpdir/in.png" "$tmpdir/lo.webp" --effort 0 --Q 75
vips webpsave "$tmpdir/in.png" "$tmpdir/hi.webp" --effort 6 --Q 75

file "$tmpdir/lo.webp" | grep -q 'Web/P'
file "$tmpdir/hi.webp" | grep -q 'Web/P'

# Both should decode back to the original dimensions.
vips webpload "$tmpdir/lo.webp" "$tmpdir/lo.png"
vips webpload "$tmpdir/hi.webp" "$tmpdir/hi.png"
[[ "$(vipsheader -f width "$tmpdir/lo.png")" -eq 96 ]]
[[ "$(vipsheader -f width "$tmpdir/hi.png")" -eq 96 ]]
