#!/usr/bin/env bash
# @testcase: usage-netpbm-pamundice-png
# @title: netpbm pamundice rebuilds diced PNG
# @description: Slices a PNG-derived image into tiles with pamdice and reassembles it with pamundice, verifying byte-exact recovery.
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

width, height, channels, payload = read_image(sys.argv[1])
expected = ast.literal_eval(sys.argv[5])
assert (width, height, channels) == (int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])), (width, height, channels)
assert payload == expected, payload
PYCASE

assert_values() { python3 "$tmpdir/pnm_assert.py" "$1" "$2" "$3" "$4" "$5"; }

printf 'P2\n4 2\n255\n10 20 30 40\n50 60 70 80\n' >"$tmpdir/in.pgm"
pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" >"$tmpdir/in-rt.pgm"

mkdir "$tmpdir/tiles"
pamdice -width=2 -height=2 -outstem="$tmpdir/tiles/tile" "$tmpdir/in-rt.pgm"
test -f "$tmpdir/tiles/tile_0_0.pgm"
test -f "$tmpdir/tiles/tile_0_1.pgm"

pamundice "$tmpdir/tiles/tile_%1d_%1a.pgm" -across=2 -down=1 >"$tmpdir/rejoined.pgm"
assert_values "$tmpdir/rejoined.pgm" 4 2 1 '[10, 20, 30, 40, 50, 60, 70, 80]'
