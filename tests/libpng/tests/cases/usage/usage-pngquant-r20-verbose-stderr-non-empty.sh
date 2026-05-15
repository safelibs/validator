#!/usr/bin/env bash
# @testcase: usage-pngquant-r20-verbose-stderr-non-empty
# @title: pngquant --verbose emits a non-empty stderr summary while still writing a paletted PNG
# @description: Generates a PNG, runs pngquant --verbose --output <path> 32 <input> capturing stderr, asserts the stderr capture is non-empty (the verbose-mode status summary), and asserts the produced output PNG has IHDR color type 3 (paletted), pinning the verbose flag's diagnostic-emission contract.
# @timeout: 120
# @tags: usage, png, pngquant, verbose, stderr, r20
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 24, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 13) & 0xff, (y * 7) & 0xff, ((x ^ y) * 5) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --verbose --output "$tmpdir/out.png" 32 "$tmpdir/in.png" 2>"$tmpdir/err.txt"
err_size=$(wc -c <"$tmpdir/err.txt")
[[ "$err_size" -gt 0 ]] || { printf 'expected non-empty verbose stderr\n' >&2; exit 1; }

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
_, _, _, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, ctype
PY
