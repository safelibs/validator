#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-from-rawvideo-rgb24
# @title: ffmpeg WebP from raw rgb24 stream
# @description: Feeds a raw rgb24 stream through ffmpeg's rawvideo demuxer, encodes it as WebP via libwebp, and verifies the result with file magic and dimensions.
# @timeout: 180
# @tags: usage, webp, video
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.rgb"
from pathlib import Path
import sys
# 4x3 rgb24 raw frame.
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(pixels)
PY

ffmpeg -hide_banner -loglevel error -y \
  -f rawvideo -pixel_format rgb24 -video_size 4x3 -framerate 1 \
  -i "$tmpdir/in.rgb" -frames:v 1 -c:v libwebp -lossless 1 \
  "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"

file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of default=noprint_wrappers=1 \
  "$tmpdir/out.webp" | tee "$tmpdir/dims"
validator_assert_contains "$tmpdir/dims" 'width=4'
validator_assert_contains "$tmpdir/dims" 'height=3'
