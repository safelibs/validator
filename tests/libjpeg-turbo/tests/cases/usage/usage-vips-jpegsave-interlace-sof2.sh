#!/usr/bin/env bash
# @testcase: usage-vips-jpegsave-interlace-sof2
# @title: vips jpegsave --interlace SOF2 marker
# @description: Saves a JPEG via vips with --interlace and verifies the encoder emits an SOF2 (progressive) frame header instead of SOF0, exercising libjpeg-turbo's progressive path.
# @timeout: 180
# @tags: usage, jpeg, image, encoder
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
W, H = 48, 32
pixels = bytearray()
for y in range(H):
    for x in range(W):
        pixels += bytes((((x * 7) ^ (y * 11)) & 255, (x * 5) & 255, (y * 9) & 255))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + bytes(pixels))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vips jpegsave "$tmpdir/in.jpg" "$tmpdir/prog.jpg" --interlace --Q 80
file "$tmpdir/prog.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

python3 - <<'PY' "$tmpdir/prog.jpg"
import sys
from pathlib import Path
data = Path(sys.argv[1]).read_bytes()
assert data[:2] == b'\xff\xd8', 'missing SOI'
assert data[-2:] == b'\xff\xd9', 'missing EOI'
assert b'\xff\xc2' in data, 'missing SOF2 (progressive frame header)'
assert b'\xff\xc0' not in data, 'unexpected SOF0 in progressive stream'
# Progressive JPEGs always emit multiple SOS scans.
assert data.count(b'\xff\xda') >= 2, 'expected multiple SOS scans in progressive JPEG'
print('SOF2 ok, scans', data.count(b'\xff\xda'))
PY
