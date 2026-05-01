#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-preset-drawing
# @title: ffmpeg WebP preset drawing encode
# @description: Encodes a PPM frame to WebP via ffmpeg with -preset drawing and verifies ffprobe reports the webp codec at the original dimensions.
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
    255, 255, 255, 0, 0, 0, 255, 255, 255, 0, 0, 0,
    0, 0, 0, 255, 255, 255, 0, 0, 0, 255, 255, 255,
    255, 255, 255, 0, 0, 0, 255, 255, 255, 0, 0, 0,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.ppm" \
  -c:v libwebp -preset drawing -q:v 80 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=codec_name,width,height -of csv=p=0:s=, "$tmpdir/out.webp" \
  | tee "$tmpdir/probe"
validator_assert_contains "$tmpdir/probe" 'webp,4,3'
