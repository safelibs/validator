#!/usr/bin/env bash
# @testcase: usage-vips-r15-jpegload-shrink-four-quarters-dimensions
# @title: vips jpegload --shrink 4 quarters both JPEG dimensions
# @description: Saves a 64x48 JPEG via cjpeg from a PPM source and runs it through vips jpegload --shrink 4, then asserts vipsheader reports width=16 and height=12 (each axis quartered), exercising the libjpeg-turbo DCT-domain integer scale-down path through vips.
# @timeout: 180
# @tags: usage, vips, jpeg, shrink
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 64, 48
data = bytes([(((x * 9) ^ (y * 5)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
file "$tmpdir/in.jpg" | grep -q 'JPEG image data'

vips jpegload "$tmpdir/in.jpg" "$tmpdir/out.v" --shrink 4
w=$(vipsheader -f width "$tmpdir/out.v")
h=$(vipsheader -f height "$tmpdir/out.v")
[[ "$w" -eq 16 ]] || { echo "width $w" >&2; exit 1; }
[[ "$h" -eq 12 ]] || { echo "height $h" >&2; exit 1; }
