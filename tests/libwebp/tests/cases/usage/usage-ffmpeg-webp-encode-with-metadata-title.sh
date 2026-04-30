#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-encode-with-metadata-title
# @title: ffmpeg WebP encode passes -metadata title= without error
# @description: Encodes a PNG to WebP via ffmpeg while passing -metadata title=validator-libwebp; libwebp does not persist generic metadata to a still WebP, so this asserts only that ffmpeg accepts the option, the resulting file is valid WebP with the original dimensions, and ffprobe re-opens it cleanly.
# @timeout: 180
# @tags: usage, webp, encode, ffmpeg, metadata
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
from PIL import Image
import sys
im = Image.new("RGB", (12, 9), (0, 0, 0))
for y in range(9):
    for x in range(12):
        im.putpixel((x, y), ((x * 41) % 256, (y * 23) % 256, ((x + y) * 17) % 256))
im.save(sys.argv[1], "PNG")
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.png" \
  -c:v libwebp -metadata title=validator-libwebp "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=, "$tmpdir/out.webp" | tee "$tmpdir/dims"
grep -Fxq '12,9' "$tmpdir/dims"
