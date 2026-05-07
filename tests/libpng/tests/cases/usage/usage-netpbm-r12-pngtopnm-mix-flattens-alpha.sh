#!/usr/bin/env bash
# @testcase: usage-netpbm-r12-pngtopnm-mix-flattens-alpha
# @title: netpbm pngtopnm -mix flattens an RGBA PNG into a 3-channel PPM
# @description: Encodes an RGBA PNG, decodes it with pngtopnm -mix which composites the alpha channel against a background to produce a 3-channel PPM, and verifies the output identifies as PPM with the original width and height.
# @timeout: 180
# @tags: usage, png, netpbm, alpha-mix
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pam" <<'PY'
import sys
W, H = 20, 12
header = f'P7\nWIDTH {W}\nHEIGHT {H}\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n'
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes((x * 12 & 0xff, y * 20 & 0xff, 32, 128))
open(sys.argv[1], 'wb').write(header.encode() + body)
PY

pamtopng "$tmpdir/in.pam" >"$tmpdir/in.png"

pngtopnm -mix "$tmpdir/in.png" >"$tmpdir/mix.ppm"

head -c 2 "$tmpdir/mix.ppm" >"$tmpdir/magic"
[[ "$(cat "$tmpdir/magic")" == "P6" ]] || {
  printf 'expected P6 PPM magic, got: %s\n' "$(cat "$tmpdir/magic")" >&2
  exit 1
}

pnmfile "$tmpdir/mix.ppm" >"$tmpdir/info"
validator_assert_contains "$tmpdir/info" 'PPM'
validator_assert_contains "$tmpdir/info" '20 by 12'
