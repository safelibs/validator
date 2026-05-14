#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r18-libwebp-preset-text-flag-accepted
# @title: ffmpeg libwebp -preset text encodes a PNG to WEBP and is detected by file(1)
# @description: Encodes a synthetic PNG via ffmpeg's libwebp encoder with -preset text and -q:v 70, asserts the produced file is identified as WEBP, and that it is non-empty.
# @timeout: 180
# @tags: usage, ffmpeg, webp, preset, r18
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (96, 48))
for y in range(48):
    for x in range(96):
        v = ((x * 5) + (y * 9)) & 0xff
        img.putpixel((x, y), (v, 255 - v, (v * 3) & 0xff))
img.save(sys.argv[1])
PY

ffmpeg -hide_banner -y -i "$tmpdir/in.png" -vcodec libwebp -preset text -q:v 70 "$tmpdir/out.webp" >"$tmpdir/ff.log" 2>&1
validator_require_file "$tmpdir/out.webp"
test -s "$tmpdir/out.webp"
file "$tmpdir/out.webp" | grep -q 'Web/P'
