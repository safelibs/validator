#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtile-png
# @title: netpbm pnmtile from PNG fixture
# @description: Tiles a PNG-derived 1x1 image with pnmtile to a 4x2 canvas and verifies the repeating pattern.
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

printf 'P2\n1 1\n255\n128\n' >"$tmpdir/seed.pgm"
pnmtopng "$tmpdir/seed.pgm" >"$tmpdir/seed.png"
pngtopnm "$tmpdir/seed.png" >"$tmpdir/seed-rt.pgm"

pnmtile 4 2 "$tmpdir/seed-rt.pgm" >"$tmpdir/tiled.pgm"
assert_values "$tmpdir/tiled.pgm" 4 2 1 '[128, 128, 128, 128, 128, 128, 128, 128]'
