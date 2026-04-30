#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-global-quality
# @title: ffmpeg WebP encode with -global_quality
# @description: Encodes a synthetic PNG to WebP with ffmpeg libwebp using the AVCodecContext -global_quality knob (FF_QP2LAMBDA-scaled) and verifies the output is a valid WebP at the expected dimensions.
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
im = Image.new("RGB", (12, 9))
for y in range(9):
    for x in range(12):
        im.putpixel((x, y), ((x * 21) % 256, (y * 29) % 256, ((x + y) * 11) % 256))
im.save(sys.argv[1], "PNG")
PY

# -global_quality is an output-side option scaled by FF_QP2LAMBDA (118).
# 60 * 118 = 7080. Place it after -i.
ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.png" \
  -c:v libwebp -global_quality 7080 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
test "$(wc -c <"$tmpdir/out.webp")" -gt 0
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'
ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=, "$tmpdir/out.webp" | tee "$tmpdir/dims"
grep -Fxq '12,9' "$tmpdir/dims"
