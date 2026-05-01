#!/usr/bin/env bash
# @testcase: usage-vips-jpegsave-restart-interval-dri
# @title: vips jpegsave --restart-interval DRI marker
# @description: Saves a JPEG via vips with --restart-interval 8 and verifies the resulting stream contains a DRI (FFDD) marker plus at least one RST0..RST7 marker, the wire-level restart structure libjpeg-turbo emits.
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
W, H = 96, 64
pixels = bytearray()
for y in range(H):
    for x in range(W):
        pixels += bytes((((x * 7) ^ (y * 5)) & 255, (x + y) & 255, (x * y) & 255))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + bytes(pixels))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vips jpegsave "$tmpdir/in.jpg" "$tmpdir/rst.jpg" --restart-interval 8 --Q 80
file "$tmpdir/rst.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

python3 - <<'PY' "$tmpdir/rst.jpg"
import sys
from pathlib import Path
data = Path(sys.argv[1]).read_bytes()
assert data[:2] == b'\xff\xd8' and data[-2:] == b'\xff\xd9', 'invalid JPEG'
assert b'\xff\xdd' in data, 'missing DRI marker for restart-interval'
rst = sum(1 for n in range(8) if bytes((0xff, 0xd0 + n)) in data)
assert rst >= 1, 'no RST markers found in entropy-coded segment'
print('DRI ok, distinct RSTn markers seen:', rst)
PY
