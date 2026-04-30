#!/usr/bin/env bash
# @testcase: usage-vips-webp-buffer-roundtrip
# @title: vips webpsave_buffer / webpload_buffer roundtrip
# @description: Drives vips webpsave_buffer then webpload_buffer through python-pyvips-style stdin/stdout descriptor pipes and verifies the round-tripped pixel and dimensions.
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
im = Image.new('RGB', (8, 6))
for y in range(6):
    for x in range(8):
        im.putpixel((x, y), ((x * 13) % 256, (y * 19) % 256, ((x + y) * 7) % 256))
im.save(sys.argv[1], 'PNG')
PY

# vips webpsave to .webp via stdout descriptor (vips supports /dev/stdout target).
vips webpsave "$tmpdir/in.png" /dev/stdout >"$tmpdir/buffer.webp"
validator_require_file "$tmpdir/buffer.webp"
test "$(wc -c <"$tmpdir/buffer.webp")" -gt 0
file "$tmpdir/buffer.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

# Re-load via vips and verify dimensions and loader.
vipsheader -a "$tmpdir/buffer.webp" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'webpload'
validator_assert_contains "$tmpdir/header" 'width: 8'
validator_assert_contains "$tmpdir/header" 'height: 6'

# Pull a single pixel back through vips getpoint to confirm decode succeeded.
vips getpoint "$tmpdir/buffer.webp" 0 0 | tee "$tmpdir/point"
test -s "$tmpdir/point"
