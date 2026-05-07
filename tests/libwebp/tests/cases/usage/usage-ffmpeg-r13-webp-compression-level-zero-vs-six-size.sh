#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r13-webp-compression-level-zero-vs-six-size
# @title: ffmpeg libwebp -compression_level 6 yields no larger file than level 0
# @description: Encodes the same RGB PNG to lossless WebP with -compression_level 0 and 6 via ffmpeg libwebp and asserts the level-6 output is no larger than the level-0 output, exercising the libwebp method effort knob's monotonic size effect at constant content.
# @timeout: 240
# @tags: usage, ffmpeg, webp
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
import sys
from PIL import Image
img = Image.new('RGB', (96, 64))
for y in range(64):
    for x in range(96):
        img.putpixel((x, y), ((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 7) & 0xff))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -lossless 1 -compression_level 0 -frames:v 1 "$tmpdir/c0.webp"
ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -lossless 1 -compression_level 6 -frames:v 1 "$tmpdir/c6.webp"

file "$tmpdir/c0.webp" | grep -q 'Web/P'
file "$tmpdir/c6.webp" | grep -q 'Web/P'

s0=$(wc -c <"$tmpdir/c0.webp")
s6=$(wc -c <"$tmpdir/c6.webp")
[[ "$s6" -le "$s0" ]] || {
    printf 'expected level-6 (%s) <= level-0 (%s)\n' "$s6" "$s0" >&2
    exit 1
}
