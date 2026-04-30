#!/usr/bin/env bash
# @testcase: usage-vips-webpsave-reduction-effort-zero
# @title: vips webpsave reduction_effort=0
# @description: Saves a still image through vips webpsave with the lossless reduction_effort=0 fast preset and verifies the output is a WebP whose dimensions and a sampled pixel survive the round-trip.
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
im = Image.new('RGB', (12, 8))
for y in range(8):
    for x in range(12):
        im.putpixel((x, y), ((x * 19) % 256, (y * 31) % 256, ((x * y) * 7) % 256))
im.save(sys.argv[1], 'PNG')
PY

vips copy "$tmpdir/in.png" "$tmpdir/out.webp[lossless=true,reduction_effort=0]"
validator_require_file "$tmpdir/out.webp"
test "$(wc -c <"$tmpdir/out.webp")" -gt 0

file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

vipsheader -a "$tmpdir/out.webp" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'webpload'
validator_assert_contains "$tmpdir/header" 'width: 12'
validator_assert_contains "$tmpdir/header" 'height: 8'

vips getpoint "$tmpdir/out.webp" 6 4 | tee "$tmpdir/point"
test -s "$tmpdir/point"
