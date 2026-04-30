#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-preset-picture
# @title: ffmpeg WebP preset picture encode
# @description: Encodes a PPM frame to WebP via ffmpeg using libwebp -preset picture and verifies the output magic and dimensions.
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
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.ppm" \
  -c:v libwebp -preset picture -q:v 75 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=codec_name,width,height -of csv=p=0:s=, "$tmpdir/out.webp" \
  | tee "$tmpdir/probe"
validator_assert_contains "$tmpdir/probe" 'webp,4,3'
