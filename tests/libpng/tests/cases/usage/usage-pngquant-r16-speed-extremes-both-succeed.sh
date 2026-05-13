#!/usr/bin/env bash
# @testcase: usage-pngquant-r16-speed-extremes-both-succeed
# @title: pngquant --speed=1 and --speed=10 both produce valid paletted PNG output
# @description: Quantises one synthetic 16x16 PNG twice with pngquant --speed=1 (slowest, best) and --speed=10 (fastest), and asserts both outputs are valid 16x16 paletted PNGs — pinning the speed-extremes encoder paths together, distinct from prior single-speed checks.
# @timeout: 120
# @tags: usage, image, png, cli, speed
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 16, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 16) & 0xff, (y * 16) & 0xff, ((x + y) * 6) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --speed=1 -o "$tmpdir/s1.png" 32 "$tmpdir/in.png"
pngquant --force --speed=10 -o "$tmpdir/s10.png" 32 "$tmpdir/in.png"

for f in "$tmpdir/s1.png" "$tmpdir/s10.png"; do
  python3 - "$f" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (16, 16), (w, h)
assert ctype == 3, ctype
PY
done
