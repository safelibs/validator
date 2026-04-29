#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-scale-filter
# @title: FFmpeg WebP scale filter
# @description: Scales a WebP image with FFmpeg and verifies the PNG output stream dimensions.
# @timeout: 180
# @tags: usage, image
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
ffmpeg -hide_banner -loglevel error -i "$tmpdir/in.webp" -vf scale=2:2 "$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'
ffprobe -hide_banner -loglevel error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=, "$tmpdir/out.png" | tee "$tmpdir/dims"
grep -Fxq '2,2' "$tmpdir/dims"
