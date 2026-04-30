#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-mp4-frames
# @title: ffmpeg WebP to MP4
# @description: Decodes a WebP to a single-frame MP4 with ffmpeg and verifies the container metadata.
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

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
ffmpeg -hide_banner -loglevel error -y -loop 1 -i "$tmpdir/in.webp" \
  -frames:v 1 -pix_fmt yuv420p -vf "scale=8:8" \
  -c:v libx264 -preset ultrafast "$tmpdir/out.mp4"
validator_require_file "$tmpdir/out.mp4"
file "$tmpdir/out.mp4" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'ISO Media'
ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=codec_name,width,height -of csv=p=0:s=, "$tmpdir/out.mp4" | tee "$tmpdir/dims"
validator_assert_contains "$tmpdir/dims" 'h264,8,8'
