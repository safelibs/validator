#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-frames-v-single
# @title: ffmpeg WebP encode with -frames:v 1
# @description: Encodes a single-frame WebP from a raw input through ffmpeg with -frames:v 1 and verifies the output via file magic and ffprobe dimensions.
# @timeout: 180
# @tags: usage, webp, video
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.ppm" \
  -frames:v 1 -c:v libwebp -lossless 1 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
test "$(wc -c <"$tmpdir/out.webp")" -gt 0

file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of default=noprint_wrappers=1 \
  "$tmpdir/out.webp" | tee "$tmpdir/dims"
validator_assert_contains "$tmpdir/dims" 'width=4'
validator_assert_contains "$tmpdir/dims" 'height=3'
