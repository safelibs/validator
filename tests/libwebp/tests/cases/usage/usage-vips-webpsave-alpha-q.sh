#!/usr/bin/env bash
# @testcase: usage-vips-webpsave-alpha-q
# @title: vips webpsave alpha_q
# @description: Saves an RGBA PNG to WebP through vips with an explicit alpha_q value and verifies bands and loader.
# @timeout: 180
# @tags: usage, webp, vips
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
from PIL import Image
import sys
im = Image.new("RGBA", (8, 6))
for y in range(6):
    for x in range(8):
        im.putpixel((x, y), ((x * 31) % 256, (y * 41) % 256, ((x + y) * 11) % 256, (x * 32) % 256))
im.save(sys.argv[1], "PNG")
PY

vips copy "$tmpdir/in.png" "$tmpdir/out.webp[alpha_q=40,Q=80]"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

vips_image=$(vipsheader -f bands "$tmpdir/out.webp")
test "$vips_image" = "4"
vips_image=$(vipsheader -f vips-loader "$tmpdir/out.webp")
test "$vips_image" = "webpload"
vips_image=$(vipsheader -f width "$tmpdir/out.webp")
test "$vips_image" = "8"
