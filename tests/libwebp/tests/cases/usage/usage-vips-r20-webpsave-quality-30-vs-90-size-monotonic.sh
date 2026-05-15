#!/usr/bin/env bash
# @testcase: usage-vips-r20-webpsave-quality-30-vs-90-size-monotonic
# @title: vips webpsave at Q=30 produces a smaller file than at Q=90 for the same source
# @description: Saves the same 64x48 PPM to WEBP twice via vips webpsave at quality 30 and 90, and asserts the file size at Q=30 is strictly less than the file size at Q=90, pinning libwebp's quality->size monotonic behavior through vips.
# @timeout: 120
# @tags: usage, vips, webp, quality, size-monotonic, r20
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 64, 48
# Mix of patterns so quality differences are visible
data = bytes((((x * 17) ^ (y * 23)) & 0xff)
              for y in range(h) for x in range(w * 3))
with open(sys.argv[1], 'wb') as f:
    f.write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips webpsave "$tmpdir/in.ppm" "$tmpdir/q30.webp" --Q 30
vips webpsave "$tmpdir/in.ppm" "$tmpdir/q90.webp" --Q 90

s30=$(stat -c %s "$tmpdir/q30.webp")
s90=$(stat -c %s "$tmpdir/q90.webp")
(( s30 > 0 && s90 > 0 )) || { echo "non-positive sizes: $s30 $s90" >&2; exit 1; }
(( s30 < s90 )) || { printf 'expected q30 < q90, got %d vs %d\n' "$s30" "$s90" >&2; exit 1; }
