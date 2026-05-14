#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r17-libwebp-quality-80-png-input-produces-webp
# @title: ffmpeg -vcodec libwebp -q:v 80 over a PNG input produces a still WEBP file
# @description: Encodes a generated PNG to WEBP via ffmpeg's libwebp encoder at -q:v 80 with -lossless 0, and asserts the resulting file is identified as WEBP by file(1) and is non-empty.
# @timeout: 180
# @tags: usage, ffmpeg, webp, quality
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (96, 72))
for y in range(72):
    for x in range(96):
        img.putpixel((x, y), ((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 7) & 0xff))
img.save(sys.argv[1])
PY

ffmpeg -hide_banner -y -i "$tmpdir/in.png" -vcodec libwebp -lossless 0 -q:v 80 "$tmpdir/out.webp" >"$tmpdir/ff.log" 2>&1
validator_require_file "$tmpdir/out.webp"
test -s "$tmpdir/out.webp"
file "$tmpdir/out.webp" | grep -q 'Web/P'
