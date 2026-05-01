#!/usr/bin/env bash
# @testcase: usage-vips-jpegsave-no-subsample
# @title: vips jpegsave no chroma subsample
# @description: Encodes a JPEG with vips jpegsave --no-subsample and confirms the SOF0 component sampling factors all read 1x1 (4:4:4) instead of the default 4:2:0.
# @timeout: 180
# @tags: usage, jpeg, image, chroma
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
pixels = bytearray()
for y in range(16):
    for x in range(16):
        pixels += bytes((((x * 9) ^ (y * 5)) & 255, (x * 11) & 255, (y * 13) & 255))
Path(sys.argv[1]).write_bytes(b"P6\n16 16\n255\n" + bytes(pixels))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
vips jpegsave "$tmpdir/in.jpg" "$tmpdir/out.jpg" --Q 90 --no-subsample

python3 - <<'PY' "$tmpdir/out.jpg"
import sys
from pathlib import Path
data = Path(sys.argv[1]).read_bytes()
idx = data.find(b'\xff\xc0')
assert idx >= 0, 'SOF0 not found'
# After SOF0: Lf(2) P(1) Y(2) X(2) Nf(1) [Ci Hi/Vi Tqi]*Nf
nf = data[idx + 9]
assert nf == 3, f'expected RGB->YCbCr Nf=3, got {nf}'
factors = []
off = idx + 10
for _ in range(nf):
    ci = data[off]
    hv = data[off + 1]
    factors.append((ci, hv >> 4, hv & 0x0F))
    off += 3
print('component factors:', factors)
# 4:4:4 -> all H=V=1 across components.
for ci, h, v in factors:
    assert h == 1 and v == 1, f'expected 1x1 sampling for 4:4:4, got C{ci} {h}x{v}'
print('no-subsample produced 4:4:4 sampling')
PY
