#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-compression-level
# @title: ffmpeg WebP compression level encode
# @description: Encodes a PPM frame to WebP with ffmpeg using -compression_level and verifies the output magic.
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
  -c:v libwebp -compression_level 6 -q:v 80 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'
ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=, "$tmpdir/out.webp" | tee "$tmpdir/dims"
grep -Fxq '4,3' "$tmpdir/dims"
