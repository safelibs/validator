#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r15-webp-frames-v-2-still-output
# @title: ffmpeg libwebp -frames:v 2 with a single PNG produces a still WebP that Pillow opens
# @description: Encodes a single PNG to lossy WebP via ffmpeg libwebp with -frames:v 2 (more frames requested than provided) and asserts the output is recognised as WebP, opens cleanly via Pillow, and reports the original 32x24 dimensions, exercising ffmpeg's behaviour when -frames:v exceeds source duration on the still encoder.
# @timeout: 240
# @tags: usage, ffmpeg, webp, still
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
import sys
from PIL import Image
img = Image.new('RGB', (32, 24))
for y in range(24):
    for x in range(32):
        img.putpixel((x, y), ((x * 7) & 0xff, (y * 11) & 0xff, ((x + y) * 5) & 0xff))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -frames:v 2 "$tmpdir/out.webp"
file "$tmpdir/out.webp" | grep -q 'Web/P'

python3 - <<'PY' "$tmpdir/out.webp"
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (32, 24), im.size
PY
