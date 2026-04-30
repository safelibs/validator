#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-quality-encode
# @title: ffmpeg WebP quality encode
# @description: Encodes a PNG to WebP with ffmpeg libwebp at a specific quality and verifies dimensions.
# @timeout: 180
# @tags: usage, webp, encode
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
from PIL import Image
import sys
im = Image.new("RGB", (8, 6), (12, 200, 80))
for y in range(6):
    for x in range(8):
        im.putpixel((x, y), ((x * 31) % 256, (y * 41) % 256, ((x + y) * 17) % 256))
im.save(sys.argv[1], "PNG")
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.png" \
  -c:v libwebp -quality 65 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'
ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=, "$tmpdir/out.webp" | tee "$tmpdir/dims"
grep -Fxq '8,6' "$tmpdir/dims"
