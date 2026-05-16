#!/usr/bin/env bash
# @testcase: usage-pngquant-r21-output-smaller-than-input
# @title: pngquant 16 produces an output PNG strictly smaller than a 128x128 truecolor input
# @description: Encodes a 128x128 truecolor PNG (no palette) then runs pngquant 16 and asserts the resulting paletted PNG byte size is strictly less than the original, pinning libpng's palette-based size reduction through pngquant's 16-color quantization.
# @timeout: 120
# @tags: usage, png, pngquant, size-reduction, r21
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 128, 128
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 17 ^ y * 5) & 0xff, (x * 23 + y * 11) & 0xff, (x * 31 ^ y * 29 ^ 0x5a) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant 16 --output "$tmpdir/out.png" "$tmpdir/in.png"

in_size=$(stat -c '%s' "$tmpdir/in.png")
out_size=$(stat -c '%s' "$tmpdir/out.png")
[[ "$out_size" -lt "$in_size" ]] || { echo "expected smaller: in=$in_size out=$out_size" >&2; exit 1; }
