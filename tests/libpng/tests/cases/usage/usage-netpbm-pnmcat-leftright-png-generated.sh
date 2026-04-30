#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmcat-leftright-png-generated
# @title: netpbm pnmcat leftright PNG generated
# @description: Concatenates two generated grayscale PNGs side-by-side with pnmcat and verifies the combined pixel row.
# @timeout: 120
# @tags: usage
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmcat-leftright-png-generated"
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
if cmd == 'values':
    magic, width, height, channels, maxval, payload = read_image(sys.argv[2])
    expected = ast.literal_eval(sys.argv[6])
    if (width, height, channels) != (int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])):
        raise SystemExit(f'unexpected shape {width}x{height}x{channels}')
    if payload != expected:
        raise SystemExit(f'unexpected payload {payload} != {expected}')
elif cmd == 'shape':
    magic, width, height, channels, maxval, payload = read_image(sys.argv[2])
    if (width, height, channels) != (int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])):
        raise SystemExit(f'unexpected shape {width}x{height}x{channels}')
elif cmd == 'maxval':
    magic, width, height, channels, maxval, payload = read_image(sys.argv[2])
    if maxval != int(sys.argv[3]):
        raise SystemExit(f'unexpected maxval {maxval}')
elif cmd == 'unique-rgb-max':
    magic, width, height, channels, maxval, payload = read_image(sys.argv[2])
    colors = {tuple(payload[i:i+channels]) for i in range(0, len(payload), channels)}
    if len(colors) > int(sys.argv[3]):
        raise SystemExit(f'too many colors: {len(colors)}')
else:
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
200
EOF
pnmtopng "$tmpdir/left.pgm" >"$tmpdir/left.png"
pnmtopng "$tmpdir/right.pgm" >"$tmpdir/right.png"
pngtopnm "$tmpdir/left.png" >"$tmpdir/left_raw.pgm"
pngtopnm "$tmpdir/right.png" >"$tmpdir/right_raw.pgm"
pnmcat -lr "$tmpdir/left_raw.pgm" "$tmpdir/right_raw.pgm" >"$tmpdir/out.pgm"
assert_values "$tmpdir/out.pgm" 2 1 1 '[10, 200]'
