#!/usr/bin/env bash
# @testcase: usage-pngquant-colors-eight-png-generated
# @title: pngquant colors eight PNG generated
# @description: Quantizes a generated PNG to eight colors with pngquant and verifies the resulting RGB palette size does not exceed eight colors.
# @timeout: 120
# @tags: usage
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-colors-eight-png-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/netpbm_assert.py" <<'PYCASE'
import ast
import sys

def read_image(path):
    data = open(path, 'rb').read()
    idx = 0
    def skip_ws():
        nonlocal idx
        while idx < len(data):
            byte = data[idx]
            if byte in b' \t\r\n':
                idx += 1
                continue
            if byte == 35:
                while idx < len(data) and data[idx] not in (10, 13):
                    idx += 1
                continue
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
    payload = list(data[idx:])
    channels = 1 if magic == b'P5' else 3
    return magic, width, height, channels, maxval, payload

cmd = sys.argv[1]
raise SystemExit(f'unknown command {cmd}')
PYCASE

assert_values() {
  python3 "$tmpdir/netpbm_assert.py" values "$1" "$2" "$3" "$4" "$5"
}
assert_maxval() {
  python3 "$tmpdir/netpbm_assert.py" maxval "$1" "$2"
}
assert_unique_rgb_max() {
  python3 "$tmpdir/netpbm_assert.py" unique-rgb-max "$1" "$2"
}

python3 - <<'PYCASE' "$tmpdir/input.ppm"
import sys
with open(sys.argv[1], 'w', encoding='ascii') as handle:
    handle.write('P3\n4 4\n255\n')
    for value in range(16):
        handle.write(f'{value * 10 % 256} {value * 30 % 256} {value * 50 % 256} ')
PYCASE
pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
pngquant --force --output "$tmpdir/out.png" 8 "$tmpdir/input.png"
pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
assert_unique_rgb_max "$tmpdir/out.ppm" 8
