#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmcrop-border-png
# @title: netpbm crop generated PNG border
# @description: Converts a generated PNG through Netpbm and verifies pnmcrop removes a zero border down to the populated center pixels.
# @timeout: 120
# @tags: usage
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmcrop-border-png"
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
if cmd == 'values':
    width, height, channels, payload = read_image(sys.argv[2])
    expected = ast.literal_eval(sys.argv[6])
    if (width, height, channels) != (int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])):
        raise SystemExit('unexpected shape')
    if payload != expected:
        raise SystemExit(f'unexpected payload {payload} != {expected}')
elif cmd == 'unique-rgb-max':
    width, height, channels, payload = read_image(sys.argv[2])
    colors = {tuple(payload[i:i+channels]) for i in range(0, len(payload), channels)}
    if len(colors) > int(sys.argv[3]):
        raise SystemExit(f'too many colors: {len(colors)}')
elif cmd == 'unique-rgb-min':
    width, height, channels, payload = read_image(sys.argv[2])
    colors = {tuple(payload[i:i+channels]) for i in range(0, len(payload), channels)}
    if len(colors) < int(sys.argv[3]):
        raise SystemExit(f'too few colors: {len(colors)}')
else:
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

cat >"$tmpdir/input.pgm" <<'EOF'
P2
4 3
255
0 0 0 0
0 5 6 0
0 7 8 0
EOF
pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
pnmcrop "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
assert_values "$tmpdir/out.pgm" 2 2 1 '[5, 6, 7, 8]'
