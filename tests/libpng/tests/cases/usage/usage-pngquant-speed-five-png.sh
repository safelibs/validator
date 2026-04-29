#!/usr/bin/env bash
# @testcase: usage-pngquant-speed-five-png
# @title: pngquant speed five PNG
# @description: Exercises pngquant speed five png through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-speed-five-png"
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
    if magic not in (b'P5', b'P6'):
        raise SystemExit(f'unsupported magic {magic!r}')
    width = int(token())
    height = int(token())
    maxval = int(token())
    if idx < len(data) and data[idx] in b' \t\r\n':
        idx += 1
    payload = list(data[idx:])
    channels = 1 if magic == b'P5' else 3
    return width, height, channels, payload

cmd = sys.argv[1]
raise SystemExit(f'unknown command {cmd}')
PYCASE

assert_values() {
  python3 "$tmpdir/netpbm_assert.py" values "$1" "$2" "$3" "$4" "$5"
}
assert_unique_rgb_max() {
  python3 "$tmpdir/netpbm_assert.py" unique-rgb-max "$1" "$2"
}
assert_unique_rgb_min() {
  python3 "$tmpdir/netpbm_assert.py" unique-rgb-min "$1" "$2"
}

python3 - <<'PYCASE' "$tmpdir/input.ppm"
import sys
with open(sys.argv[1], 'w', encoding='ascii') as handle:
    handle.write('P3\n3 3\n255\n')
    for value in range(9):
        red = (value * 23) % 256
        green = (value * 47) % 256
        blue = (value * 71) % 256
        handle.write(f'{red} {green} {blue} ')
PYCASE
pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.ppm"
assert_unique_rgb_min "$tmpdir/raw.ppm" 5
pngquant --force --speed 5 --output "$tmpdir/out.png" 4 "$tmpdir/input.png"
pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
assert_unique_rgb_max "$tmpdir/out.ppm" 4
