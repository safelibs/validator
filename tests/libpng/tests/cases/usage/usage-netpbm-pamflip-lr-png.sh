#!/usr/bin/env bash
# @testcase: usage-netpbm-pamflip-lr-png
# @title: netpbm pamflip leftright on PNG-derived image
# @description: Round-trips a small image through PNG, flips it left-right with pamflip, and checks horizontal mirroring of pixel values.
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

printf 'P2\n4 1\n255\n10 20 30 40\n' >"$tmpdir/in.pgm"
pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" >"$tmpdir/in-rt.pgm"

pamflip -leftright "$tmpdir/in-rt.pgm" >"$tmpdir/flipped.pgm"
assert_values "$tmpdir/flipped.pgm" 4 1 1 '[40, 30, 20, 10]'
