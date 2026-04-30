#!/usr/bin/env bash
# @testcase: usage-netpbm-pamlevels-brighten-png
# @title: netpbm pamlevels brightening factor
# @description: Maps midtone grey (0x40) to bright (0x80) via pamlevels on a PNG-derived ppm and verifies the brightened pixel value.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic 2x1 RGB PNG with values 0x40 and 0x80.
printf 'P3\n2 1\n255\n64 64 64  128 128 128\n' >"$tmpdir/in.ppm"
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngtopnm "$tmpdir/in.png" >"$tmpdir/raw.ppm"

# pamlevels with two mappings: 0x40 -> 0x80 (factor 2) and 0x80 -> 0xFF (factor ~2).
pamlevels \
  -from1 'rgb:40/40/40' -to1 'rgb:80/80/80' \
  -from2 'rgb:80/80/80' -to2 'rgb:ff/ff/ff' \
  "$tmpdir/raw.ppm" >"$tmpdir/out.ppm"

pamfile "$tmpdir/out.ppm" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '2 by 1'

python3 - "$tmpdir/out.ppm" <<'PY'
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
if magic not in (b'P5', b'P6'):
    raise SystemExit(f'expected P5 or P6, got {magic!r}')
w = int(tok()); h = int(tok()); _ = int(tok())
if data[idx] in b' \t\r\n':
    idx += 1
payload = list(data[idx:])
ch = 1 if magic == b'P5' else 3
if (w, h) != (2, 1):
    raise SystemExit(f'unexpected dimensions {w}x{h}')
# Pixel 0 (input 0x40) should map to ~0x80, pixel 1 (input 0x80) should map to ~0xff.
p0 = payload[0:ch]
p1 = payload[ch:ch * 2]
if not all(0x70 <= v <= 0x90 for v in p0):
    raise SystemExit(f'expected pixel0 ~0x80, got {p0}')
if not all(v >= 0xf0 for v in p1):
    raise SystemExit(f'expected pixel1 ~0xff, got {p1}')
PY
