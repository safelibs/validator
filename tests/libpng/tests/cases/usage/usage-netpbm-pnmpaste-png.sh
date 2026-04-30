#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmpaste-png
# @title: netpbm pnmpaste onto PNG-derived canvas
# @description: Pastes a small subimage onto a PNG-derived canvas with pnmpaste and verifies pixel placement.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/pnm_assert.py" <<'PYCASE'
import ast
import sys

def read_image(path):
    data = open(path, 'rb').read()
    idx = 0
    def skip_ws():
        nonlocal idx
        while idx < len(data):
            if data[idx] in b' \t\r\n':
                idx += 1
            elif data[idx] == 35:
                while idx < len(data) and data[idx] not in (10, 13):
                    idx += 1
            else:
                break
    def token():
        nonlocal idx
        skip_ws()
        start = idx
        while idx < len(data) and data[idx] not in b' \t\r\n':
            idx += 1
        return data[start:idx]
    magic = token()
    width = int(token())
    height = int(token())
    maxval = int(token())
    if idx < len(data) and data[idx] in b' \t\r\n':
        idx += 1
    channels = 1 if magic == b'P5' else 3
    return width, height, channels, list(data[idx:])

cmd = sys.argv[1]
if cmd == 'values':
    width, height, channels, payload = read_image(sys.argv[2])
    expected = ast.literal_eval(sys.argv[6])
    assert (width, height, channels) == (int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])), (width, height, channels)
    assert payload == expected, payload
else:
    raise SystemExit(cmd)
PYCASE

assert_values() { python3 "$tmpdir/pnm_assert.py" values "$1" "$2" "$3" "$4" "$5"; }

# 3x3 black canvas, paste a 2x2 white tile at (1,1).
printf 'P2\n3 3\n255\n0 0 0 0 0 0 0 0 0\n' >"$tmpdir/canvas.pgm"
pnmtopng "$tmpdir/canvas.pgm" >"$tmpdir/canvas.png"
printf 'P2\n2 2\n255\n255 255 255 255\n' >"$tmpdir/tile.pgm"

pngtopnm "$tmpdir/canvas.png" >"$tmpdir/canvas-rt.pgm"
pnmpaste "$tmpdir/tile.pgm" 1 1 "$tmpdir/canvas-rt.pgm" >"$tmpdir/out.pgm"
assert_values "$tmpdir/out.pgm" 3 3 1 '[0, 0, 0, 0, 255, 255, 0, 255, 255]'
