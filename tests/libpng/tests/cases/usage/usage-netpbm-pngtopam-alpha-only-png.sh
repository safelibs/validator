#!/usr/bin/env bash
# @testcase: usage-netpbm-pngtopam-alpha-only-png
# @title: netpbm pngtopam -alpha extracts the alpha plane only
# @description: Synthesises an RGBA PNG by pamstack-ing RGB and alpha planes and pamtopng-encoding the result, then runs pngtopam -alpha on it and verifies the extracted alpha PGM matches the original alpha plane byte-for-byte.
# @timeout: 180
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pngtopam-alpha-only-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a 4x2 RGBA image with a deterministic alpha plane.
printf 'P2\n4 2\n255\n10 20 30 40\n50 60 70 80\n' >"$tmpdir/r.pgm"
printf 'P2\n4 2\n255\n100 110 120 130\n140 150 160 170\n' >"$tmpdir/g.pgm"
printf 'P2\n4 2\n255\n200 190 180 170\n160 150 140 130\n' >"$tmpdir/b.pgm"
printf 'P2\n4 2\n255\n255 192 128 64\n0 64 128 255\n' >"$tmpdir/a.pgm"

pamstack -tupletype=RGB_ALPHA "$tmpdir/r.pgm" "$tmpdir/g.pgm" "$tmpdir/b.pgm" "$tmpdir/a.pgm" \
  >"$tmpdir/rgba.pam"
pamtopng "$tmpdir/rgba.pam" >"$tmpdir/rgba.png"
file "$tmpdir/rgba.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopam -alpha "$tmpdir/rgba.png" >"$tmpdir/alpha.pgm"
pamfile "$tmpdir/alpha.pgm" | tee "$tmpdir/alpha-pamfile"
validator_assert_contains "$tmpdir/alpha-pamfile" '4 by 2'
# pngtopam -alpha emits PGM (or PBM if alpha is 1-bit); our alpha has more
# than two distinct values so it must be PGM raw.
validator_assert_contains "$tmpdir/alpha-pamfile" 'PGM raw'

python3 - "$tmpdir/alpha.pgm" <<'PY'
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
if magic != b'P5':
    raise SystemExit(f'expected P5, got {magic!r}')
w = int(tok())
h = int(tok())
maxv = int(tok())
if (w, h, maxv) != (4, 2, 255):
    raise SystemExit(f'unexpected header {w}x{h}@{maxv}')
if data[idx] in b' \t\r\n':
    idx += 1
payload = list(data[idx:])
expected = [255, 192, 128, 64, 0, 64, 128, 255]
if payload != expected:
    raise SystemExit(f'alpha payload mismatch: got {payload} expected {expected}')
PY
