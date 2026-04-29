#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmcat-leftright-png
# @title: netpbm pnmcat left-right PNG
# @description: Exercises netpbm pnmcat left-right png through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmcat-leftright-png"
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

cat >"$tmpdir/left.pgm" <<'EOF'
P2
1 1
255
10
EOF
cat >"$tmpdir/right.pgm" <<'EOF'
P2
1 1
255
20
EOF
pnmcat -leftright "$tmpdir/left.pgm" "$tmpdir/right.pgm" >"$tmpdir/joined.pgm"
pnmtopng "$tmpdir/joined.pgm" >"$tmpdir/out.png"
pngtopnm "$tmpdir/out.png" >"$tmpdir/out.pgm"
assert_values "$tmpdir/out.pgm" 2 1 1 '[10, 20]'
