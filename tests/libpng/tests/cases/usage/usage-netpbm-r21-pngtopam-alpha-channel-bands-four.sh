#!/usr/bin/env bash
# @testcase: usage-netpbm-r21-pngtopam-alpha-channel-bands-four
# @title: netpbm pngtopam on RGBA PNG yields a 4-channel PAM (depth 4)
# @description: Builds an RGBA PNG, decodes via pngtopam, and asserts pamfile reports the PAM tuple depth as 4 (R,G,B,A), pinning libpng's alpha channel preservation as the fourth band in the netpbm PAM stream.
# @timeout: 120
# @tags: usage, png, netpbm, pngtopam, alpha, r21
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 6, 6
body = bytearray()
for y in range(H):
    for x in range(W):
        body += bytes((x * 40 % 256, y * 40 % 256, 64))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + body)
PY
python3 - "$tmpdir/mask.pgm" <<'PY'
import sys
W, H = 6, 6
body = bytearray()
for y in range(H):
    for x in range(W):
        body.append(255 if (x % 2) == 0 else 64)
open(sys.argv[1], 'wb').write(f'P5\n{W} {H}\n255\n'.encode() + body)
PY

pnmtopng -alpha "$tmpdir/mask.pgm" "$tmpdir/in.ppm" >"$tmpdir/rgba.png"
pngtopam -alphapam "$tmpdir/rgba.png" >"$tmpdir/out.pam"

pamfile "$tmpdir/out.pam" >"$tmpdir/info.txt"
# pamfile output reports "<W> by <H> by 4" for a 4-band image
grep -Eq 'by[[:space:]]+4[[:space:]]+maxval' "$tmpdir/info.txt"
