#!/usr/bin/env bash
# @testcase: usage-vips-webpsave-min-size
# @title: vips webpsave min_size
# @description: Saves a still image as WebP through vips with min_size=true and verifies the output is a WebP whose dimensions and loader survive vipsheader.
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
im = Image.new('RGB', (10, 6))
for y in range(6):
    for x in range(10):
        im.putpixel((x, y), ((x * 11) % 256, (y * 29) % 256, ((x * y) * 5) % 256))
im.save(sys.argv[1], 'PNG')
PY

vips copy "$tmpdir/in.png" "$tmpdir/out.webp[min_size=true,Q=70]"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

vipsheader -a "$tmpdir/out.webp" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'webpload'
validator_assert_contains "$tmpdir/header" 'width: 10'
validator_assert_contains "$tmpdir/header" 'height: 6'

# Sanity-check a pixel decodes back through vips.
vips getpoint "$tmpdir/out.webp" 5 3 | tee "$tmpdir/point"
test -s "$tmpdir/point"
