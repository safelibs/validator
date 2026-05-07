#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r15-webp-pix-fmt-yuva420p-rgba-source
# @title: ffmpeg libwebp -pix_fmt yuva420p preserves RGBA source through to a WebP that Pillow reads as RGBA
# @description: Encodes an RGBA PNG to WebP via ffmpeg -c:v libwebp -pix_fmt yuva420p -frames:v 1 and asserts Pillow re-opens the result with mode == 'RGBA' and the original geometry, exercising the alpha-bearing pix_fmt round-trip through ffmpeg/libwebp.
# @timeout: 240
# @tags: usage, ffmpeg, webp, alpha
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
import sys
from PIL import Image
img = Image.new('RGBA', (40, 30))
for y in range(30):
    for x in range(40):
        img.putpixel((x, y), ((x * 7) & 0xff, (y * 13) & 0xff, ((x + y) * 5) & 0xff, ((x * y) & 0xff)))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -pix_fmt yuva420p -frames:v 1 "$tmpdir/out.webp"
file "$tmpdir/out.webp" | grep -q 'Web/P'

python3 - <<'PY' "$tmpdir/out.webp"
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (40, 30), im.size
    assert im.mode == 'RGBA', im.mode
PY
