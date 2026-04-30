#!/usr/bin/env bash
# @testcase: usage-ffmpeg-webp-compression-level-explicit-six
# @title: ffmpeg WebP encode with explicit -compression_level 6
# @description: Encodes a synthesized PPM frame to WebP with ffmpeg using -compression_level 6 explicitly along with -qscale:v 75, then verifies the output WebP magic and that ffprobe reports the expected width/height.
# @timeout: 180
# @tags: usage, webp, encode, ffmpeg
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
w, h = 8, 6
pixels = bytearray()
for y in range(h):
    for x in range(w):
        pixels += bytes([(x * 31 + 7) % 256, (y * 47 + 11) % 256, ((x ^ y) * 53) % 256])
Path(sys.argv[1]).write_bytes(b"P6\n%d %d\n255\n" % (w, h) + bytes(pixels))
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.ppm" \
  -c:v libwebp -compression_level 6 -qscale:v 75 "$tmpdir/out.webp"
validator_require_file "$tmpdir/out.webp"
test "$(wc -c <"$tmpdir/out.webp")" -gt 0

file "$tmpdir/out.webp" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'Web/P image'

ffprobe -hide_banner -loglevel error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=, "$tmpdir/out.webp" | tee "$tmpdir/dims"
grep -Fxq '8,6' "$tmpdir/dims"
