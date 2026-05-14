#!/usr/bin/env bash
# @testcase: usage-pngquant-r17-skip-if-larger-tiny-paletted-exits-nonzero
# @title: pngquant --skip-if-larger exits non-zero on an already-tiny input
# @description: Quantises an 8x8 noisy PNG with --skip-if-larger at 256 colours; since the source is too small to shrink further, pngquant must skip writing and exit non-zero (98 historically).
# @timeout: 120
# @tags: usage, image, png, pngquant, skip-if-larger
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 8, 8
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 32, y * 32, (x + y) * 16))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

set +e
pngquant --skip-if-larger --force --output "$tmpdir/out.png" 256 "$tmpdir/in.png"
rc=$?
set -e

[[ "$rc" -ne 0 ]] || {
  printf 'expected non-zero exit from --skip-if-larger; got 0\n' >&2
  exit 1
}
