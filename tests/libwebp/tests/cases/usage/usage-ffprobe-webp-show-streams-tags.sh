#!/usr/bin/env bash
# @testcase: usage-ffprobe-webp-show-streams-tags
# @title: ffprobe -show_streams on WebP exposes a stream block
# @description: Encodes a PNG to WebP with ffmpeg, then runs ffprobe -show_streams and confirms the output contains a [STREAM] section, the codec_name=webp tag, and the expected width/height.
# @timeout: 180
# @tags: usage, webp, ffprobe
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
from PIL import Image
import sys
im = Image.new("RGB", (11, 8), (0, 0, 0))
for y in range(8):
    for x in range(11):
        im.putpixel((x, y), ((x * 13) % 256, (y * 29) % 256, ((x + y) * 31) % 256))
im.save(sys.argv[1], "PNG")
PY

ffmpeg -hide_banner -loglevel error -y -i "$tmpdir/in.png" \
  -c:v libwebp "$tmpdir/in.webp"
validator_require_file "$tmpdir/in.webp"

ffprobe -hide_banner -loglevel error -show_streams "$tmpdir/in.webp" >"$tmpdir/streams"
cat "$tmpdir/streams"

validator_assert_contains "$tmpdir/streams" '[STREAM]'
validator_assert_contains "$tmpdir/streams" '[/STREAM]'
validator_assert_contains "$tmpdir/streams" 'codec_name=webp'
validator_assert_contains "$tmpdir/streams" 'width=11'
validator_assert_contains "$tmpdir/streams" 'height=8'
