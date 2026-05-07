#!/usr/bin/env bash
# @testcase: usage-vips-r14-webpload-buffer-bands-three-rgb
# @title: vips webpload of an RGB-source WebP reports bands=3
# @description: Encodes an RGB PNG to WebP via Pillow, runs it through vips webpload to a .v file, and asserts vipsheader reports bands=3 (RGB) and matching dimensions, exercising the WebP RGB decode path through vips.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
img = Image.new('RGB', (40, 30))
for y in range(30):
    for x in range(40):
        img.putpixel((x, y), ((x * 9) & 0xff, (y * 11) & 0xff, ((x ^ y) * 5) & 0xff))
img.save(sys.argv[1], 'WEBP', quality=90)
PY

vips webpload "$tmpdir/in.webp" "$tmpdir/out.v"

vipsheader -a "$tmpdir/out.v" >"$tmpdir/hdr.txt"
validator_assert_contains "$tmpdir/hdr.txt" 'bands: 3'
validator_assert_contains "$tmpdir/hdr.txt" 'width: 40'
validator_assert_contains "$tmpdir/hdr.txt" 'height: 30'
