#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r16-libwebp-lossless-flag-produces-vp8l
# @title: ffmpeg -c:v libwebp -lossless 1 produces a WebP whose RIFF payload identifies as VP8L
# @description: Encodes a small PNG to WEBP via ffmpeg -c:v libwebp -lossless 1, asserts the result carries the standard RIFF/WEBP header and contains a 'VP8L' four-character chunk identifier in the first 64 bytes — the libwebp lossless container signature.
# @timeout: 120
# @tags: usage, ffmpeg, webp, lossless
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.png" <<'PY'
import sys
from PIL import Image
img = Image.new('RGB', (32, 24))
for y in range(24):
    for x in range(32):
        img.putpixel((x, y), ((x * 7) & 0xff, (y * 11) & 0xff, 64))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -lossless 1 -frames:v 1 "$tmpdir/out.webp"
file "$tmpdir/out.webp" | grep -q 'Web/P'

head -c 64 "$tmpdir/out.webp" >"$tmpdir/head.bin"
grep -aq 'RIFF' "$tmpdir/head.bin"
grep -aq 'WEBP' "$tmpdir/head.bin"
grep -aq 'VP8L' "$tmpdir/head.bin"
