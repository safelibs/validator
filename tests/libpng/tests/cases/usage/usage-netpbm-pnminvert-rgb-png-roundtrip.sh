#!/usr/bin/env bash
# @testcase: usage-netpbm-pnminvert-rgb-png-roundtrip
# @title: netpbm pnminvert RGB PNG roundtrip
# @description: Inverts a generated RGB PNG with pnminvert and verifies the inverted per-channel pixel values after a PNG roundtrip.
# @timeout: 120
# @tags: usage
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnminvert-rgb-png-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/pgm_assert.py" <<'PYCASE'
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
  python3 "$tmpdir/pgm_assert.py" values "$1" "$2" "$3" "$4" "$5"
}
assert_shape() {
  python3 "$tmpdir/pgm_assert.py" shape "$1" "$2" "$3" "$4"
}
assert_unique_rgb_max() {
  python3 "$tmpdir/pgm_assert.py" unique-rgb-max "$1" "$2"
}

cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 1
255
10 100 200   30 60 90
EOF
pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.ppm"
pnminvert "$tmpdir/raw.ppm" >"$tmpdir/out.ppm"
assert_values "$tmpdir/out.ppm" 2 1 3 '[245, 155, 55, 225, 195, 165]'
