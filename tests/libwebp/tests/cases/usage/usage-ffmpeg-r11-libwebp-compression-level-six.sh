#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r11-libwebp-compression-level-six
# @title: ffmpeg libwebp accepts -compression_level 6 and emits a valid WebP
# @description: Encodes an RGB PNG to WebP with -compression_level 6 (above the libwebp default of 4) and confirms the output is a structurally valid VP8 WebP.
# @timeout: 180
# @tags: usage, ffmpeg, webp
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
import sys
from PIL import Image
img = Image.new('RGB', (16, 16), (200, 60, 30))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp \
       -compression_level 6 -frames:v 1 "$tmpdir/out.webp"

file "$tmpdir/out.webp" | grep -q 'Web/P'
webpinfo "$tmpdir/out.webp" | grep -q 'No error detected'
