#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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
if cmd == 'values':
    width, height, channels, maxval, payload = read_image(sys.argv[2])
    expected = ast.literal_eval(sys.argv[6])
    assert (width, height, channels) == (int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]))
    assert payload == expected, payload
elif cmd == 'shape':
    width, height, channels, maxval, payload = read_image(sys.argv[2])
    assert (width, height, channels) == (int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]))
elif cmd == 'maxval':
    width, height, channels, maxval, payload = read_image(sys.argv[2])
    assert maxval == int(sys.argv[3]), maxval
else:
    raise SystemExit(cmd)
PYCASE

assert_values() { python3 "$tmpdir/pnm_assert.py" values "$1" "$2" "$3" "$4" "$5"; }
assert_shape() { python3 "$tmpdir/pnm_assert.py" shape "$1" "$2" "$3" "$4"; }

case "$case_id" in
  usage-netpbm-batch11-pnminvert-gray)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 1
255
0 200
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnminvert >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[255, 55]'
    ;;
  usage-netpbm-batch11-pnmflip-left-right)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 1
255
10 20 30  40 50 60
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnmflip -leftright >"$tmpdir/out.ppm"
    assert_values "$tmpdir/out.ppm" 2 1 3 '[40, 50, 60, 10, 20, 30]'
    ;;
  usage-netpbm-batch11-pamflip-top-bottom)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
1 2
255
25
75
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pamflip -tb >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 1 2 1 '[75, 25]'
    ;;
  usage-netpbm-batch11-pnmcat-three-wide)
    printf 'P2\n1 1\n255\n10\n' >"$tmpdir/a.pgm"
    printf 'P2\n1 1\n255\n20\n' >"$tmpdir/b.pgm"
    printf 'P2\n1 1\n255\n30\n' >"$tmpdir/c.pgm"
    pnmcat -lr "$tmpdir/a.pgm" "$tmpdir/b.pgm" "$tmpdir/c.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 3 1 1 '[10, 20, 30]'
    ;;
  usage-netpbm-batch11-pnmscale-xysize)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 2
255
80 80
80 80
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnmscale -xysize 4 2 >"$tmpdir/out.pgm"
    assert_shape "$tmpdir/out.pgm" 2 2 1
    ;;
  usage-netpbm-batch11-pamchannel-blue)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 1
255
10 40 70  20 50 80
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pamchannel 2 | pamtopnm -assume >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[70, 80]'
    ;;
  usage-netpbm-batch11-pnmdepth-31)
    printf 'P2\n1 1\n255\n255\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnmdepth 31 >"$tmpdir/out.pgm"
    python3 "$tmpdir/pnm_assert.py" maxval "$tmpdir/out.pgm" 31
    ;;
  usage-netpbm-batch11-pnmcut-region)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
3 1
255
10 20 30
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnmcut 1 0 2 1 >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[20, 30]'
    ;;
  usage-netpbm-batch11-pnmcat-three-tall)
    printf 'P2\n1 1\n255\n5\n' >"$tmpdir/a.pgm"
    printf 'P2\n1 1\n255\n15\n' >"$tmpdir/b.pgm"
    printf 'P2\n1 1\n255\n25\n' >"$tmpdir/c.pgm"
    pnmcat -tb "$tmpdir/a.pgm" "$tmpdir/b.pgm" "$tmpdir/c.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 1 3 1 '[5, 15, 25]'
    ;;
  usage-netpbm-batch11-pnmscale-double)
    printf 'P2\n1 1\n255\n99\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnmscale 2 >"$tmpdir/out.pgm"
    assert_shape "$tmpdir/out.pgm" 2 2 1
    ;;
  *)
    printf 'unknown libpng eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
