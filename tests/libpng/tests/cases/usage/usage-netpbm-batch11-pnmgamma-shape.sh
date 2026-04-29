#!/usr/bin/env bash
# @testcase: usage-netpbm-batch11-pnmgamma-shape
# @title: netpbm pnmgamma shape
# @description: Applies gamma correction to a PNG-derived grayscale image with pnmgamma.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-batch11-pnmgamma-shape"
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

printf 'P2\n2 1\n255\n64 128\n' >"$tmpdir/input.pgm"
pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
pngtopnm "$tmpdir/input.png" | pnmgamma 2.0 >"$tmpdir/out.pgm"
assert_shape "$tmpdir/out.pgm" 2 1 1
