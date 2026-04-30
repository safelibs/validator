#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-roundtrip-to-ppm
# @title: ffmpeg WebP encode then decode back to PPM
# @description: Encodes a synthesized PPM frame to WebP with ffmpeg using -lossless 1, then re-decodes the WebP via ffmpeg back to a PPM image and asserts the decoded PPM has the original dimensions and the file magic 'Netpbm image data'.
# @timeout: 180
# @tags: usage, webp, ffmpeg, roundtrip
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
w, h = 5, 4
pixels = bytearray()
for y in range(h):
    for x in range(w):
        pixels += bytes([(x * 47 + 3) % 256, (y * 71 + 5) % 256, ((x * y + 9) * 11) % 256])
Path(sys.argv[1]).write_bytes(b"P6\n%d %d\n255\n" % (w, h) + bytes(pixels))
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.ppm" \
  -c:v libwebp -lossless 1 "$tmpdir/mid.webp"
validator_require_file "$tmpdir/mid.webp"
file "$tmpdir/mid.webp" | tee "$tmpdir/midfile"
validator_assert_contains "$tmpdir/midfile" 'Web/P image'

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/mid.webp" \
  -frames:v 1 "$tmpdir/out.ppm"
validator_require_file "$tmpdir/out.ppm"
file "$tmpdir/out.ppm" | tee "$tmpdir/outfile"
validator_assert_contains "$tmpdir/outfile" 'Netpbm image data'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=, "$tmpdir/out.ppm" | tee "$tmpdir/dims"
grep -Fxq '5,4' "$tmpdir/dims"
