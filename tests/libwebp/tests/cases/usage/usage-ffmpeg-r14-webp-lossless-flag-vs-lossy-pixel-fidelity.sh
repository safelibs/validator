#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r14-webp-lossless-flag-vs-lossy-pixel-fidelity
# @title: ffmpeg libwebp -lossless 1 round-trips RGB pixels exactly
# @description: Encodes a synthetic RGB PNG to WebP with ffmpeg -c:v libwebp -lossless 1, decodes back to PNG, and asserts every pixel is byte-identical to the source via a Pillow tobytes() comparison, exercising the lossless encode/decode contract.
# @timeout: 240
# @tags: usage, ffmpeg, webp, lossless
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png"
import sys
from PIL import Image
img = Image.new('RGB', (40, 32))
for y in range(32):
    for x in range(40):
        img.putpixel((x, y), ((x * 11) & 0xff, (y * 13) & 0xff, ((x ^ y) * 7) & 0xff))
img.save(sys.argv[1], 'PNG')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -lossless 1 -frames:v 1 "$tmpdir/out.webp"
file "$tmpdir/out.webp" | grep -q 'Web/P'

ffmpeg -loglevel error -y -i "$tmpdir/out.webp" "$tmpdir/decoded.png"

python3 - <<'PY' "$tmpdir/in.png" "$tmpdir/decoded.png"
import sys
from PIL import Image
a = Image.open(sys.argv[1]).convert('RGB')
b = Image.open(sys.argv[2]).convert('RGB')
assert a.size == b.size, (a.size, b.size)
assert a.tobytes() == b.tobytes(), 'lossless RGB round-trip not byte-identical'
PY
