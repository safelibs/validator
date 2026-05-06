#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r10-webp-pix-fmt-yuva420p
# @title: ffmpeg WebP encode keeps alpha plane via yuva420p pix_fmt
# @description: Encodes an RGBA PNG to WebP with -pix_fmt yuva420p and confirms the resulting WebP decodes back with an alpha channel preserved.
# @timeout: 180
# @tags: usage, ffmpeg, webp
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
import sys
from PIL import Image
img = Image.new('RGBA', (32, 32))
for y in range(32):
    for x in range(32):
        a = 0 if (x + y) % 4 == 0 else 200
        img.putpixel((x, y), (220, 30, 60, a))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp \
       -pix_fmt yuva420p -frames:v 1 "$tmpdir/out.webp"

file "$tmpdir/out.webp" | grep -q 'Web/P'

python3 - <<'PY' "$tmpdir/out.webp"
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.mode in ('RGBA', 'P'), im.mode
    rgba = im.convert('RGBA')
    alphas = {rgba.getpixel((x, y))[3] for x in range(0, 32, 4) for y in range(0, 32, 4)}
    assert min(alphas) < 100, f'expected at least one transparent pixel, got {sorted(alphas)}'
print('ok')
PY
