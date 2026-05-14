#!/usr/bin/env bash
# @testcase: usage-pngquant-r17-gradient-output-not-larger-than-input
# @title: pngquant on a 64x64 gradient produces output no larger than the input
# @description: Quantises a 64x64 multi-colour gradient PNG with pngquant 64 colors and asserts the output PNG byte size is less than or equal to the input PNG byte size, exercising the typical "smaller paletted output" win path.
# @timeout: 120
# @tags: usage, image, png, pngquant, size
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 64, 64
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 4) & 0xff, (y * 4) & 0xff, ((x ^ y) * 3) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --output "$tmpdir/out.png" 64 "$tmpdir/in.png"
validator_require_file "$tmpdir/out.png"

size_in=$(stat -c '%s' "$tmpdir/in.png")
size_out=$(stat -c '%s' "$tmpdir/out.png")

[[ "$size_out" -le "$size_in" ]] || {
  printf 'expected out <= in, got %s > %s\n' "$size_out" "$size_in" >&2
  exit 1
}
