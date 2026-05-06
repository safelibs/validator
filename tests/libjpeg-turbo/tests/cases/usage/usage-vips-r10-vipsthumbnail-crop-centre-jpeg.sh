#!/usr/bin/env bash
# @testcase: usage-vips-r10-vipsthumbnail-crop-centre-jpeg
# @title: vipsthumbnail --smartcrop centre crops a JPEG to a square
# @description: Generates a 100x60 JPEG, then runs vipsthumbnail with size 32x32 and --smartcrop centre. Verifies the output JPEG is exactly 32x32 (the crop fills the box) and decodes back through vipsheader.
# @timeout: 180
# @tags: usage, jpeg, image, thumbnail
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 100, 60
data = bytes([(i * 7 + (i // 3) * 5) & 0xFF for i in range(w * h * 3)])
open(sys.argv[1], "wb").write(f"P6\n{w} {h}\n255\n".encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vipsthumbnail "$tmpdir/in.jpg" \
    --size 32x32 \
    --smartcrop centre \
    -o "$tmpdir/%s-thumb.jpg"

[[ -s "$tmpdir/in-thumb.jpg" ]]
vipsheader "$tmpdir/in-thumb.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '32x32'

file "$tmpdir/in-thumb.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
