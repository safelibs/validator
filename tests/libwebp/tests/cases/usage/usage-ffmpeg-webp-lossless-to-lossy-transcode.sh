#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-lossless-to-lossy-transcode
# @title: ffmpeg WebP transcoded between lossless and lossy
# @description: Encodes a PPM source to a lossless WebP via ffmpeg, then re-encodes that lossless WebP to a lossy WebP, asserting both outputs are valid WebP with matching dimensions.
# @timeout: 240
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

# Lossless first.
ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.ppm" \
  -c:v libwebp -lossless 1 "$tmpdir/lossless.webp"
validator_require_file "$tmpdir/lossless.webp"
file "$tmpdir/lossless.webp" | tee "$tmpdir/file_lossless"
validator_assert_contains "$tmpdir/file_lossless" 'Web/P image'

# Now transcode that lossless WebP into lossy WebP.
ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/lossless.webp" \
  -c:v libwebp -lossless 0 -quality 70 "$tmpdir/lossy.webp"
validator_require_file "$tmpdir/lossy.webp"
file "$tmpdir/lossy.webp" | tee "$tmpdir/file_lossy"
validator_assert_contains "$tmpdir/file_lossy" 'Web/P image'

for f in "$tmpdir/lossless.webp" "$tmpdir/lossy.webp"; do
  ffprobe -hide_banner -loglevel error -select_streams v:0 \
    -show_entries stream=width,height -of csv=p=0:s=, "$f" >"$tmpdir/dims"
  grep -Fxq '4,3' "$tmpdir/dims"
done
