#!/usr/bin/env bash
# @testcase: usage-netpbm-pamarith-add-png
# @title: netpbm pamarith add PNG inputs
# @description: Adds two PNG-derived PAM images with pamarith --add and checks per-pixel sums.
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

printf 'P2\n2 1\n255\n10 20\n' >"$tmpdir/a.pgm"
printf 'P2\n2 1\n255\n30 40\n' >"$tmpdir/b.pgm"
pnmtopng "$tmpdir/a.pgm" >"$tmpdir/a.png"
pnmtopng "$tmpdir/b.pgm" >"$tmpdir/b.png"

pngtopnm "$tmpdir/a.png" >"$tmpdir/a-rt.pgm"
pngtopnm "$tmpdir/b.png" >"$tmpdir/b-rt.pgm"

pamarith -add "$tmpdir/a-rt.pgm" "$tmpdir/b-rt.pgm" >"$tmpdir/sum.pgm"
assert_values "$tmpdir/sum.pgm" 2 1 1 '[40, 60]'
