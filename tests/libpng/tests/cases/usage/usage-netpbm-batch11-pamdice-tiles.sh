#!/usr/bin/env bash
# @testcase: usage-netpbm-batch11-pamdice-tiles
# @title: netpbm pamdice tiles
# @description: Slices a grayscale image into one-pixel tiles with pamdice.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-batch11-pamdice-tiles"
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
    return width, height, channels, maxval, list(data[idx:])

cmd = sys.argv[1]
raise SystemExit(cmd)
PYCASE

assert_values() { python3 "$tmpdir/pnm_assert.py" values "$1" "$2" "$3" "$4" "$5"; }
assert_shape() { python3 "$tmpdir/pnm_assert.py" shape "$1" "$2" "$3" "$4"; }

printf 'P2\n2 2\n255\n0 50\n100 150\n' >"$tmpdir/input.pgm"
mkdir "$tmpdir/tiles"
pamdice -width=1 -height=1 -outstem="$tmpdir/tiles/tile" "$tmpdir/input.pgm"
test -f "$tmpdir/tiles/tile_0_0.pgm"
test -f "$tmpdir/tiles/tile_0_1.pgm"
test -f "$tmpdir/tiles/tile_1_0.pgm"
test -f "$tmpdir/tiles/tile_1_1.pgm"
