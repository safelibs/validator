#!/usr/bin/env bash
# @testcase: usage-vips-jpegload-shrink-on-load
# @title: vips jpegload shrink-on-load 2x
# @description: Loads a 64x32 JPEG via vips jpegload with shrink=2 and confirms libjpeg-turbo's DCT-domain shrink returns a 32x16 image without a separate resize step.
# @timeout: 180
# @tags: usage, jpeg, image, decoder
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
W, H = 64, 32
pixels = bytearray()
for y in range(H):
    for x in range(W):
        pixels += bytes((((x * 4) ^ (y * 8)) & 255, (x * 4) & 255, (y * 8) & 255))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + bytes(pixels))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vips jpegload "$tmpdir/in.jpg" "$tmpdir/shrunk.v" --shrink 2
vipsheader "$tmpdir/shrunk.v" | tee "$tmpdir/header.out"

python3 - <<'PY' "$tmpdir/header.out"
import sys
from pathlib import Path
line = Path(sys.argv[1]).read_text().strip()
# vipsheader default format: "<path>: WIDTHxHEIGHT band-format ..."
parts = line.split()
dims = next(p for p in parts if 'x' in p and p.split('x')[0].isdigit())
w, h = (int(v) for v in dims.split('x')[:2])
assert (w, h) == (32, 16), f'expected 32x16 from shrink=2, got {w}x{h}'
print('shrink-on-load 32x16 ok')
PY
