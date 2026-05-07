#!/usr/bin/env bash
# @testcase: usage-netpbm-r14-pngtopnm-byrow-decodes-rgb
# @title: netpbm pngtopnm -byrow decodes a non-interlaced RGB PNG row-at-a-time path
# @description: Encodes a synthetic 16x16 RGB PPM via pnmtopng (non-interlaced), then decodes it back with pngtopnm -byrow and verifies the result is a P6 PPM of the original dimensions — locking in pngtopnm/pngtopam's row-by-row decode path through libpng's png_read_row() on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, png, netpbm, byrow
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
        b += bytes((x * 16 & 0xff, y * 16 & 0xff, 128))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

# Row-by-row decode requires non-interlaced input (which pnmtopng default produces).
pngtopnm -byrow "$tmpdir/in.png" >"$tmpdir/out.pnm"

head -c 2 "$tmpdir/out.pnm" >"$tmpdir/magic"
[[ "$(cat "$tmpdir/magic")" == "P6" ]] || {
  printf 'expected P6 PPM magic, got: %s\n' "$(cat "$tmpdir/magic")" >&2
  exit 1
}

pnmfile "$tmpdir/out.pnm" >"$tmpdir/info"
validator_assert_contains "$tmpdir/info" 'PPM'
validator_assert_contains "$tmpdir/info" '16 by 16'
