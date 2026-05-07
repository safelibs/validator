#!/usr/bin/env bash
# @testcase: usage-pngquant-r13-short-q-quality-range
# @title: pngquant -Q short flag accepts a min-max quality range and writes a valid PNG
# @description: Quantises a synthetic PNG with pngquant -Q 0-100 (the documented short alias of --quality with a min-max range covering the full bound) and verifies the resulting file is a valid paletted PNG of the original dimensions with at most the requested colour count, locking in the short -Q alias as functional on Ubuntu 24.04 — distinguishing it from the existing --quality long-form tests.
# @timeout: 120
# @tags: usage, image, png, cli, short-flag, quality
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

pngquant --force -Q 0-100 -o "$tmpdir/out.png" 32 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (32, 32), (w, h)
assert ctype == 3, f'expected paletted PNG (ctype 3), got {ctype}'

# Walk to the PLTE chunk; entry count must not exceed the requested 32.
idx = 8
plte_len = None
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    chunk_type = data[idx + 4:idx + 8].decode('ascii')
    if chunk_type == 'PLTE':
        plte_len = length
    idx += 8 + length + 4
    if chunk_type == 'IEND':
        break
assert plte_len is not None, 'no PLTE chunk in paletted PNG'
assert plte_len % 3 == 0, f'PLTE length {plte_len} not a multiple of 3'
entries = plte_len // 3
assert 1 <= entries <= 32, f'unexpected PLTE entry count {entries}'
PY
