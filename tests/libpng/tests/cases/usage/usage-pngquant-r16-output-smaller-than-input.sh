#!/usr/bin/env bash
# @testcase: usage-pngquant-r16-output-smaller-than-input
# @title: pngquant on a 32x32 RGB PNG produces output strictly smaller than input
# @description: Builds a moderately busy 32x32 RGB PNG via pnmtopng, runs pngquant --force --quality 40-70 with 32 colors, and asserts the quantised output file size is strictly less than the input PNG size — pinning the size-reduction property of palette quantisation on a compressible image.
# @timeout: 120
# @tags: usage, image, png, cli, size
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
        b += bytes(((x * 8) & 0xff, (y * 8) & 0xff, ((x ^ y) * 4) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --quality 40-70 -o "$tmpdir/out.png" 32 "$tmpdir/in.png"

in_size=$(stat -c '%s' "$tmpdir/in.png")
out_size=$(stat -c '%s' "$tmpdir/out.png")
test "$out_size" -lt "$in_size"
