#!/usr/bin/env bash
# @testcase: usage-netpbm-pgmnoise-seeded-png
# @title: netpbm pgmnoise seeded determinism into PNG
# @description: Generates a deterministic noise PGM with pgmnoise -randomseed twice, encodes one to PNG, decodes it back and verifies the round-tripped bytes match the second seeded run.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pgmnoise -randomseed 1234 8 8 >"$tmpdir/a.pgm"
pgmnoise -randomseed 1234 8 8 >"$tmpdir/b.pgm"

# Both seeded runs must be identical.
cmp "$tmpdir/a.pgm" "$tmpdir/b.pgm"

pamfile "$tmpdir/a.pgm" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '8 by 8'

# Round-trip via PNG.
pnmtopng "$tmpdir/a.pgm" >"$tmpdir/a.png"
file "$tmpdir/a.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopnm "$tmpdir/a.png" >"$tmpdir/a-back.pgm"

# The PNG round-trip must preserve every pixel of the seeded noise.
python3 - "$tmpdir/a.pgm" "$tmpdir/a-back.pgm" <<'PY'
import sys

def read_image(path):
    data = open(path, 'rb').read()
    idx = 0
    def skip_ws():
        nonlocal idx
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
        nonlocal idx
        skip_ws()
        s = idx
        while idx < len(data) and data[idx] not in b' \t\r\n':
            idx += 1
        return data[s:idx]
    magic = tok()
    w = int(tok()); h = int(tok()); _ = int(tok())
    if data[idx] in b' \t\r\n':
        idx += 1
    return magic, w, h, list(data[idx:])

ma, wa, ha, pa = read_image(sys.argv[1])
mb, wb, hb, pb = read_image(sys.argv[2])
if (ma, wa, ha) != (mb, wb, hb):
    raise SystemExit(f'shape mismatch: {(ma, wa, ha)} vs {(mb, wb, hb)}')
if (wa, ha) != (8, 8):
    raise SystemExit(f'unexpected dimensions {wa}x{ha}')
if len(pa) != 64 or len(pb) != 64:
    raise SystemExit(f'expected 64 grayscale bytes, got {len(pa)} and {len(pb)}')
if pa != pb:
    raise SystemExit('PNG round-trip changed pixel values')
if len(set(pa)) < 4:
    raise SystemExit(f'expected noise to span multiple values, got {len(set(pa))}')
PY
