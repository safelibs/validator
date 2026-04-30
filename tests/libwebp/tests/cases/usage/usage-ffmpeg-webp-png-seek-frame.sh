#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-png-seek-frame
# @title: ffmpeg WebP to PNG with -ss seek
# @description: Loops a still WebP under ffmpeg with -loop 1 and -ss to seek into the synthetic timeline, decodes a single frame to PNG, and verifies the PNG output.
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

# -loop 1 + -r 5 turns the still WebP into a synthetic 5fps stream so -ss can
# select frame 3 (t=0.4s) before decoding a single frame to PNG.
ffmpeg -hide_banner -loglevel error -y -loop 1 -r 5 -i "$tmpdir/in.webp" \
  -ss 0.4 -frames:v 1 "$tmpdir/out.png"
validator_require_file "$tmpdir/out.png"

file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of default=noprint_wrappers=1 \
  "$tmpdir/out.png" | tee "$tmpdir/dims"
validator_assert_contains "$tmpdir/dims" 'width=4'
validator_assert_contains "$tmpdir/dims" 'height=3'
