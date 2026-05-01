#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-hint-photo
# @title: ffmpeg WebP hint photo encode
# @description: Encodes a PPM frame to lossy WebP through ffmpeg's libwebp encoder using -preset photo and confirms the output is a valid WebP with the expected dimensions.
# @timeout: 180
# @tags: usage, webp, encode
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    10, 10, 10, 30, 30, 30, 60, 60, 60, 90, 90, 90,
    120, 80, 40, 80, 120, 40, 40, 80, 120, 200, 60, 30,
    250, 250, 250, 200, 200, 200, 150, 150, 150, 100, 100, 100,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.ppm" \
  -c:v libwebp -preset photo -q:v 70 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=codec_name,width,height -of csv=p=0:s=, "$tmpdir/out.webp" \
  | tee "$tmpdir/probe"
validator_assert_contains "$tmpdir/probe" 'webp,4,3'
