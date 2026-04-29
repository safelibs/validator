#!/usr/bin/env bash
# @testcase: usage-pngquant-colors-three-png
# @title: pngquant three color PNG
# @description: Exercises pngquant three color png through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-colors-three-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/netpbm_assert.py" <<'PY'
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
PY

assert_values() {
  python3 "$tmpdir/netpbm_assert.py" values "$1" "$2" "$3" "$4" "$5"
}
assert_unique_rgb_max() {
  python3 "$tmpdir/netpbm_assert.py" unique-rgb-max "$1" "$2"
}
assert_unique_gray_max() {
  python3 "$tmpdir/netpbm_assert.py" unique-gray-max "$1" "$2"
}

cat >"$tmpdir/input.ppm" <<'EOF'
P3
4 1
255
255 0 0   0 255 0   0 0 255   255 255 255
EOF
pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
pngquant --force --output "$tmpdir/out.png" 3 "$tmpdir/input.png"
pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
assert_unique_rgb_max "$tmpdir/out.ppm" 3
