#!/usr/bin/env bash
# @testcase: usage-vips-webpsave-smart-subsample
# @title: vips webpsave smart_subsample
# @description: Saves a PNG to WebP through vips with smart_subsample=true and verifies the output dimensions via vipsheader.
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
im = Image.new("RGB", (16, 12))
for y in range(12):
    for x in range(16):
        im.putpixel((x, y), ((x * 13) % 256, (y * 19) % 256, ((x + y) * 7) % 256))
im.save(sys.argv[1], "PNG")
PY

vips copy "$tmpdir/in.png" "$tmpdir/out.webp[smart_subsample=true,Q=70]"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

vips_image=$(vipsheader -f width "$tmpdir/out.webp")
test "$vips_image" = "16"
vips_image=$(vipsheader -f height "$tmpdir/out.webp")
test "$vips_image" = "12"
vips_image=$(vipsheader -f vips-loader "$tmpdir/out.webp")
test "$vips_image" = "webpload"
