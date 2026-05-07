#!/usr/bin/env bash
# @testcase: usage-netpbm-r12-pngtopnm-alpha-extracts-mask
# @title: netpbm pngtopnm -alpha extracts the alpha channel as a PGM
# @description: Encodes an RGBA PNG via pamrgbatopng, decodes it back with pngtopnm -alpha, and verifies the result is a PGM grayscale image with the same width and height as the source — the -alpha flag must produce a single-channel mask.
# @timeout: 180
# @tags: usage, png, netpbm, alpha
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build an RGBA PAM and convert it to PNG.
python3 - "$tmpdir/in.pam" <<'PY'
import sys
W, H = 24, 16
header = f'P7\nWIDTH {W}\nHEIGHT {H}\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n'
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes((x * 10 & 0xff, y * 15 & 0xff, 64, x * 8 & 0xff))
open(sys.argv[1], 'wb').write(header.encode() + body)
PY

pamtopng "$tmpdir/in.pam" >"$tmpdir/in.png"

pngtopnm -alpha "$tmpdir/in.png" >"$tmpdir/alpha.pgm"

# A PGM file must start with the P5 magic.
head -c 2 "$tmpdir/alpha.pgm" >"$tmpdir/magic"
[[ "$(cat "$tmpdir/magic")" == "P5" ]] || {
  printf 'expected P5 PGM magic, got: %s\n' "$(cat "$tmpdir/magic")" >&2
  exit 1
}

pnmfile "$tmpdir/alpha.pgm" >"$tmpdir/info"
validator_assert_contains "$tmpdir/info" 'PGM'
validator_assert_contains "$tmpdir/info" '24 by 16'
