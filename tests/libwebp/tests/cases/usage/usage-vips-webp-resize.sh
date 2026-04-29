#!/usr/bin/env bash
# @testcase: usage-vips-webp-resize
# @title: vips webp resize
# @description: Resizes a WebP fixture with vips through libwebp decoding.
# @timeout: 180
# @tags: usage, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    python3 - <<'PY' "$tmpdir/in.ppm"
import sys
open(sys.argv[1], 'wb').write(b'P6\n4 3\n255\n' + bytes([255,0,0,0,255,0,0,0,255,255,255,0,255,0,255,0,255,255,40,40,40,220,220,220,100,20,30,20,100,30,20,30,100,200,120,20]))
PY
    cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
    vips resize "$tmpdir/in.webp" "$tmpdir/out.png" 0.5
vipsheader "$tmpdir/out.png"
