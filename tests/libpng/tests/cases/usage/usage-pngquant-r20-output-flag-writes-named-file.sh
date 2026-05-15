#!/usr/bin/env bash
# @testcase: usage-pngquant-r20-output-flag-writes-named-file
# @title: pngquant --output explicit-path writes the paletted PNG to that named file
# @description: Generates a PNG, runs pngquant --output <explicit-path> 32 <input>, and asserts the explicit-path file exists with PNG magic and IHDR color type 3 (paletted), while no -fs8.png sibling is created next to the input, pinning the --output flag's destination behavior.
# @timeout: 120
# @tags: usage, png, pngquant, output, paletted, r20
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
        b += bytes(((x * 9) & 0xff, (y * 11) & 0xff, ((x + y) * 5) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --output "$tmpdir/named.png" 32 "$tmpdir/in.png"
validator_require_file "$tmpdir/named.png"

# No sibling -fs8.png was created next to the input
if [[ -e "$tmpdir/in-fs8.png" ]]; then
  printf 'unexpected sibling fs8.png exists\n' >&2; exit 1
fi

python3 - "$tmpdir/named.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
_, _, _, ctype = struct.unpack('>IIBB', data[16:26])
assert ctype == 3, f'expected paletted (3), got {ctype}'
PY
