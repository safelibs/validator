#!/usr/bin/env bash
# @testcase: usage-pngquant-r9-quality-bounds-zero
# @title: pngquant quality 0-100 emits valid PNG
# @description: Quantizes a synthetic PNG at the maximally permissive quality range 0-100 and verifies the output is a valid PNG file.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new("RGBA", (32, 32))
for y in range(32):
    for x in range(32):
        img.putpixel((x, y), ((x * 8) & 0xff, (y * 8) & 0xff, (x ^ y) & 0xff, 255))
img.save(sys.argv[1], "PNG")
PY

pngquant --quality=0-100 --force --output "$tmpdir/out.png" 256 "$tmpdir/in.png"
file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
