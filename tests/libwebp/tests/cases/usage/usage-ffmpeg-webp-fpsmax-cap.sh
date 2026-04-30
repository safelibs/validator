#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-fpsmax-cap
# @title: ffmpeg WebP encode with -fpsmax 30 cap
# @description: Encodes a single PNG frame to WebP with ffmpeg using -fpsmax 30 as a frame-rate ceiling and verifies the output is WebP with the expected dimensions.
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
im = Image.new("RGB", (10, 7), (0, 0, 0))
for y in range(7):
    for x in range(10):
        im.putpixel((x, y), ((x * 23) % 256, (y * 37) % 256, ((x + y) * 19) % 256))
im.save(sys.argv[1], "PNG")
PY

# -fpsmax is an output-side option; it must follow the -i input.
ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.png" \
  -fpsmax 30 -c:v libwebp "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'
ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=, "$tmpdir/out.webp" | tee "$tmpdir/dims"
grep -Fxq '10,7' "$tmpdir/dims"
