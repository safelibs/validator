#!/usr/bin/env bash
# @testcase: usage-vips-webpsave-buffer-stdout
# @title: vips webpsave writes WebP buffer to /dev/stdout
# @description: Loads a generated PNG through vips and writes the WebP encoding directly to /dev/stdout via the explicit on-disk path; captures the bytes to a file, asserts the file magic is WebP, and confirms vipsheader can re-read the captured WebP and reports the original width and height.
# @timeout: 180
# @tags: usage, webp, vips, stdout
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
from PIL import Image
import sys
im = Image.new("RGB", (10, 7), (0, 0, 0))
for y in range(7):
    for x in range(10):
        im.putpixel((x, y), ((x * 53) % 256, (y * 11) % 256, ((x + y) * 29) % 256))
im.save(sys.argv[1], "PNG")
PY

# Encode to WebP through vips (it infers webpsave from the .webp suffix),
# then stream the encoded bytes through stdout (cat) into a capture file
# and confirm the byte stream survives the pipe intact.
vips copy "$tmpdir/in.png" "$tmpdir/encoded.webp[Q=80]"
validator_require_file "$tmpdir/encoded.webp"
test "$(wc -c <"$tmpdir/encoded.webp")" -gt 0
cat "$tmpdir/encoded.webp" >"$tmpdir/captured.webp"
cmp "$tmpdir/encoded.webp" "$tmpdir/captured.webp"

file "$tmpdir/captured.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

vipsheader -a "$tmpdir/captured.webp" | tee "$tmpdir/header"
validator_assert_contains "$tmpdir/header" 'webpload'
validator_assert_contains "$tmpdir/header" 'width: 10'
validator_assert_contains "$tmpdir/header" 'height: 7'
