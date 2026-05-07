#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r12-webp-quality-low-vs-high-size-monotonic
# @title: ffmpeg libwebp encode -quality 5 produces a smaller file than -quality 95
# @description: Encodes the same RGB PNG to WebP twice via ffmpeg libwebp at -quality 5 and -quality 95 and confirms the low-quality file is strictly smaller, exercising the lossy quality scale.
# @timeout: 240
# @tags: usage, ffmpeg, webp, quality
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
        img.putpixel((x, y), ((x * 5) & 255, (y * 7) & 255, ((x ^ y) * 3) & 255))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -quality 5  -frames:v 1 "$tmpdir/lo.webp"
ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -quality 95 -frames:v 1 "$tmpdir/hi.webp"

file "$tmpdir/lo.webp" | grep -q 'Web/P'
file "$tmpdir/hi.webp" | grep -q 'Web/P'

lo=$(wc -c <"$tmpdir/lo.webp")
hi=$(wc -c <"$tmpdir/hi.webp")
[[ "$lo" -lt "$hi" ]] || {
    printf 'expected lo (%s) < hi (%s)\n' "$lo" "$hi" >&2
    exit 1
}
