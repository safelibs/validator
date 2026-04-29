#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmscale-half-png-generated
# @title: netpbm pnmscale half PNG generated
# @description: Scales a generated grayscale PNG to half size with pnmscale and verifies the resulting one-by-one shape.
# @timeout: 120
# @tags: usage
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmscale-half-png-generated"
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

cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 2
255
80 80
80 80
EOF
pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
pnmscale 0.5 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
assert_shape "$tmpdir/out.pgm" 1 1 1
