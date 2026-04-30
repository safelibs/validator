#!/usr/bin/env bash
# @testcase: usage-netpbm-pamthreshold-threshold-half-png
# @title: netpbm pamthreshold -threshold=0.5 on PNG-derived PGM
# @description: Decodes a 4x1 PNG-derived grayscale ramp and runs pamthreshold -threshold=0.5, verifying that values strictly below 0.5 (mid-gray) become black and values at or above become white in a BLACKANDWHITE PAM.
# @timeout: 180
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamthreshold-threshold-half-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 4 grayscale samples spanning below, just below, just above, and above
# the half-of-maxval threshold.
printf 'P2\n4 1\n255\n0 100 200 255\n' >"$tmpdir/in.pgm"
pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
file "$tmpdir/in.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopnm "$tmpdir/in.png" >"$tmpdir/raw.pgm"
pamthreshold -threshold=0.5 "$tmpdir/raw.pgm" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '4 by 1'
validator_assert_contains "$tmpdir/pamfile" 'BLACKANDWHITE'

# Convert the PAM result to PBM for a deterministic byte check. A PBM raw
# image has one bit per pixel; netpbm uses 0 = black, 1 = white in PBM.
pamtopnm "$tmpdir/out.pam" >"$tmpdir/out.pbm"
python3 - "$tmpdir/out.pbm" <<'PY'
import sys

data = open(sys.argv[1], 'rb').read()
idx = 0


def skip_ws():
    global idx
    while idx < len(data):
        b = data[idx]
        if b in b' \t\r\n':
            idx += 1
            continue
        if b == 35:
            while idx < len(data) and data[idx] not in (10, 13):
                idx += 1
            continue
        break


def tok():
    global idx
    skip_ws()
    s = idx
    while idx < len(data) and data[idx] not in b' \t\r\n':
        idx += 1
    return data[s:idx]


magic = tok()
if magic != b'P4':
    raise SystemExit(f'expected P4, got {magic!r}')
w = int(tok())
h = int(tok())
if (w, h) != (4, 1):
    raise SystemExit(f'unexpected dims {w}x{h}')
if data[idx] in b' \t\r\n':
    idx += 1
payload = data[idx:]
if len(payload) != 1:
    raise SystemExit(f'expected 1 packed byte, got {len(payload)}')
byte = payload[0]
# Bits, MSB-first. PBM convention: 1 = black, 0 = white.
bits = [(byte >> (7 - i)) & 1 for i in range(4)]
# Inputs were 0, 100, 200, 255 against a maxval-relative threshold of 0.5
# (== 127.5/255). pamthreshold sends values >= threshold to white (bit 0)
# and below to black (bit 1).
expected = [1, 1, 0, 0]
if bits != expected:
    raise SystemExit(f'expected bits {expected}, got {bits}')
PY
