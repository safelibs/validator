#!/usr/bin/env bash
# @testcase: usage-netpbm-r14-pnmtopng-ztxt-compresses-text
# @title: netpbm pnmtopng -ztxt emits a zTXt chunk instead of a tEXt chunk
# @description: Encodes a synthetic PPM with pnmtopng -ztxt pointing at a "Comment Hello" descriptor file and walks the resulting PNG to confirm a zTXt chunk is present and that no tEXt chunk was emitted for the same payload — locking in that -ztxt selects the compressed-text path through libpng, distinct from the tEXt path covered elsewhere.
# @timeout: 120
# @tags: usage, png, netpbm, ztxt
# @client: netpbm

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
        b += bytes((x * 16 & 0xff, y * 16 & 0xff, 96))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

# pnmtopng documents that -ztxt picks zTXt unless the keyword starts with 'A' or 'T'.
printf 'Comment Hello world\n' >"$tmpdir/text.txt"

pnmtopng -ztxt "$tmpdir/text.txt" "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
idx = 8
ztxt = 0
text = 0
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    if ctype == 'zTXt':
        ztxt += 1
    elif ctype == 'tEXt':
        text += 1
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if ztxt < 1:
    raise SystemExit(f'expected at least one zTXt chunk, got {ztxt}')
if text != 0:
    raise SystemExit(f'-ztxt path must not emit tEXt, got {text}')
PY
