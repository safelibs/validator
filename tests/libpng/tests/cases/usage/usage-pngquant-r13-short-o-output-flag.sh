#!/usr/bin/env bash
# @testcase: usage-pngquant-r13-short-o-output-flag
# @title: pngquant -o short flag writes the quantised PNG to the supplied path
# @description: Quantises a synthetic PNG using the documented short -o alias of --output and verifies the named target file exists, is recognised as a PNG, and matches the source dimensions, locking in the short-flag form of the output-path option as a working synonym of --output.
# @timeout: 120
# @tags: usage, image, png, cli, short-flag
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 32, 32
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 8) & 0xff, (y * 8) & 0xff, ((x + y) * 4) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force -o "$tmpdir/out.png" 16 "$tmpdir/in.png"

# Output file must exist, be non-empty, and be a valid 32x32 PNG.
test -s "$tmpdir/out.png"
python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
w, h = struct.unpack('>II', data[16:24])
assert (w, h) == (32, 32), (w, h)
PY
