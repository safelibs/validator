#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r11-libwebp-quality-100-larger-than-default
# @title: ffmpeg libwebp -quality 100 produces a larger file than the default
# @description: Encodes the same noisy 200x200 RGB PNG twice via libwebp (default quality and -quality 100) and asserts the maximum-quality output is strictly larger, exercising the encoder quality knob.
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
img = Image.new('RGB', (200, 200))
for y in range(200):
    for x in range(200):
        img.putpixel((x, y), ((x * 7 + y * 5) % 255, (x * 3 + y * 11) % 255, (x * y) % 255))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp \
       -frames:v 1 "$tmpdir/default.webp"
ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp \
       -quality 100 -frames:v 1 "$tmpdir/q100.webp"

default_size=$(stat -c '%s' "$tmpdir/default.webp")
q100_size=$(stat -c '%s' "$tmpdir/q100.webp")

[[ "$q100_size" -gt "$default_size" ]] || {
    printf 'expected q100 (%s) > default (%s)\n' "$q100_size" "$default_size" >&2
    exit 1
}
