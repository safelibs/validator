#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r14-webp-quality-mid-vs-high-monotonic-size
# @title: ffmpeg libwebp -quality 30 yields a no-larger file than -quality 90
# @description: Encodes the same PNG to lossy WebP with ffmpeg libwebp at -quality 30 and -quality 90 (default lossy mode) and asserts the q30 file is no larger than q90, exercising the lossy quality knob's monotonic size effect through ffmpeg.
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
        img.putpixel((x, y), ((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 7) & 0xff))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -quality 30 -frames:v 1 "$tmpdir/q30.webp"
ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -quality 90 -frames:v 1 "$tmpdir/q90.webp"

file "$tmpdir/q30.webp" | grep -q 'Web/P'
file "$tmpdir/q90.webp" | grep -q 'Web/P'

s30=$(wc -c <"$tmpdir/q30.webp")
s90=$(wc -c <"$tmpdir/q90.webp")
[[ "$s30" -le "$s90" ]] || {
    printf 'expected q30 (%s) <= q90 (%s)\n' "$s30" "$s90" >&2
    exit 1
}
