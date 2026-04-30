#!/usr/bin/env bash
# @testcase: usage-vips-webpsave-min-size-false
# @title: vips webpsave min_size=false
# @description: Saves a still image as WebP through vips with min_size=false explicitly disabled and verifies the result decodes back as WebP via vipsheader and vips getpoint.
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
im = Image.new('RGB', (11, 7))
for y in range(7):
    for x in range(11):
        im.putpixel((x, y), ((x * 13) % 256, (y * 41) % 256, ((x + y) * 9) % 256))
im.save(sys.argv[1], 'PNG')
PY

vips copy "$tmpdir/in.png" "$tmpdir/out.webp[min_size=false,Q=70]"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

vipsheader -a "$tmpdir/out.webp" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'webpload'
validator_assert_contains "$tmpdir/header" 'width: 11'
validator_assert_contains "$tmpdir/header" 'height: 7'

vips getpoint "$tmpdir/out.webp" 5 3 | tee "$tmpdir/point"
test -s "$tmpdir/point"
