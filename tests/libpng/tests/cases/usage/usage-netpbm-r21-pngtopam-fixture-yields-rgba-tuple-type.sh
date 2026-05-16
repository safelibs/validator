#!/usr/bin/env bash
# @testcase: usage-netpbm-r21-pngtopam-fixture-yields-rgba-tuple-type
# @title: netpbm pngtopam on an RGBA PNG emits a PAM with tuple type RGB_ALPHA
# @description: Generates an 8x8 RGBA PNG via pnmtopng -alpha, decodes back with pngtopam, and asserts pamfile reports tuple type "RGB_ALPHA", pinning libpng's RGBA color-type round-trip through netpbm's PAM tuple-type labelling.
# @timeout: 120
# @tags: usage, png, netpbm, pngtopam, rgba, r21
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# RGB PPM
python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 8, 8
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes((x * 32 % 256, y * 32 % 256, (x + y) * 16 % 256))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + body)
PY

# alpha mask as PGM
python3 - "$tmpdir/mask.pgm" <<'PY'
import sys
W, H = 8, 8
body = bytearray()
for y in range(H):
    for x in range(W):
        body.append(255 if (x + y) % 2 == 0 else 0)
open(sys.argv[1], 'wb').write(f'P5\n{W} {H}\n255\n'.encode() + body)
PY

pnmtopng -alpha "$tmpdir/mask.pgm" "$tmpdir/in.ppm" >"$tmpdir/rgba.png"
pngtopam -alphapam "$tmpdir/rgba.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" >"$tmpdir/info.txt"
grep -Fq 'RGB_ALPHA' "$tmpdir/info.txt"
