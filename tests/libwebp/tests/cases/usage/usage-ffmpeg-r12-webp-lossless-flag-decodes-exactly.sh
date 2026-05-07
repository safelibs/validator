#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r12-webp-lossless-flag-decodes-exactly
# @title: ffmpeg libwebp -lossless 1 round-trips RGB pixels byte-for-byte
# @description: Encodes a synthetic RGB PNG with ffmpeg -c:v libwebp -lossless 1 then decodes back to PPM via ffmpeg and asserts the output pixel buffer matches the input byte-for-byte.
# @timeout: 240
# @tags: usage, ffmpeg, webp, lossless
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.png" "$tmpdir/in.ppm"
import sys
from PIL import Image
w, h = 32, 24
img = Image.new('RGB', (w, h))
data = [((x * 11) & 255, (y * 13) & 255, ((x + y) * 17) & 255)
        for y in range(h) for x in range(w)]
img.putdata(data)
img.save(sys.argv[1], 'PNG')
img.save(sys.argv[2], 'PPM')
PY

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -lossless 1 -frames:v 1 "$tmpdir/out.webp"
file "$tmpdir/out.webp" | grep -q 'Web/P'

ffmpeg -loglevel error -y -i "$tmpdir/out.webp" "$tmpdir/out.ppm"

# Compare pixel buffers (not headers, in case the line ending differs).
python3 - <<'PY' "$tmpdir/in.ppm" "$tmpdir/out.ppm"
import sys
def pixels(path):
    raw = open(path, 'rb').read()
    # Skip 3 header lines: P6\n WxH\n maxval\n
    idx = 0
    for _ in range(3):
        idx = raw.index(b'\n', idx) + 1
    return raw[idx:]
a = pixels(sys.argv[1])
b = pixels(sys.argv[2])
assert a == b, (len(a), len(b), a[:16].hex(), b[:16].hex())
PY
