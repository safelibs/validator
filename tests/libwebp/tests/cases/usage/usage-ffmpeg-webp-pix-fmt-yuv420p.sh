#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-pix-fmt-yuv420p
# @title: ffmpeg WebP encode with explicit pix_fmt yuv420p
# @description: Encodes a PNG to WebP through ffmpeg libwebp forcing -pix_fmt yuv420p and verifies the output is a valid WebP at the expected dimensions and that ffprobe reports yuv420p as the pixel format.
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
im = Image.new("RGB", (16, 8))
for y in range(8):
    for x in range(16):
        im.putpixel((x, y), ((x * 13) % 256, (y * 23) % 256, ((x + y) * 9) % 256))
im.save(sys.argv[1], "PNG")
PY

# -pix_fmt is an output-side option; place after -i.
ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.png" \
  -c:v libwebp -pix_fmt yuv420p "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height,pix_fmt -of default=nokey=0:noprint_wrappers=1 \
  "$tmpdir/out.webp" | tee "$tmpdir/probe"
validator_assert_contains "$tmpdir/probe" 'width=16'
validator_assert_contains "$tmpdir/probe" 'height=8'
validator_assert_contains "$tmpdir/probe" 'pix_fmt=yuv420p'
