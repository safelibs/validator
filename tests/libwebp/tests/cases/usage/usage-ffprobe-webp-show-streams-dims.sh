#!/usr/bin/env bash
# @testcase: usage-ffprobe-webp-show-streams-dims
# @title: ffprobe -show_streams WebP width/height
# @description: Runs ffprobe with -show_streams against a WebP image and asserts the parsed width/height from the full stream dump.
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
# 6x5 PPM so we can verify a non-default size.
w, h = 6, 5
pixels = bytearray()
for y in range(h):
    for x in range(w):
        pixels += bytes([(x * 41) % 256, (y * 53) % 256, ((x + y) * 17) % 256])
Path(sys.argv[1]).write_bytes(b"P6\n%d %d\n255\n" % (w, h) + bytes(pixels))
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
validator_require_file "$tmpdir/in.webp"

ffprobe -hide_banner -loglevel error -show_streams "$tmpdir/in.webp" \
  >"$tmpdir/streams"
test -s "$tmpdir/streams"
validator_assert_contains "$tmpdir/streams" '[STREAM]'
validator_assert_contains "$tmpdir/streams" 'width=6'
validator_assert_contains "$tmpdir/streams" 'height=5'
