#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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
else:
    raise SystemExit(f'unknown command {cmd}')
PYCASE

assert_values() {
  python3 "$tmpdir/netpbm_assert.py" values "$1" "$2" "$3" "$4" "$5"
}
assert_unique_rgb_max() {
  python3 "$tmpdir/netpbm_assert.py" unique-rgb-max "$1" "$2"
}

case "$case_id" in
  usage-netpbm-pnmcat-leftright-png)
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
    ;;
  usage-netpbm-pnmcat-topbottom-png)
    cat >"$tmpdir/top.pgm" <<'EOF'
P2
1 1
255
10
EOF
    cat >"$tmpdir/bottom.pgm" <<'EOF'
P2
1 1
255
20
EOF
    pnmcat -topbottom "$tmpdir/top.pgm" "$tmpdir/bottom.pgm" >"$tmpdir/stacked.pgm"
    pnmtopng "$tmpdir/stacked.pgm" >"$tmpdir/out.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 1 2 1 '[10, 20]'
    ;;
  usage-netpbm-pnmflip-r180-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 2
255
1 2
3 4
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmflip -r180 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 2 1 '[4, 3, 2, 1]'
    ;;
  usage-netpbm-pnmcut-middle-column-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
3 2
255
1 2 3
4 5 6
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmcut 1 0 1 2 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 1 2 1 '[2, 5]'
    ;;
  usage-netpbm-pnmcut-middle-row-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 3
255
1 2
3 4
5 6
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmcut 0 1 2 1 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[3, 4]'
    ;;
  usage-netpbm-pnmscale-half-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 2
255
77 77
77 77
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmscale 0.5 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 1 1 1 '[77]'
    ;;
  usage-pngquant-colors-sixteen-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
8 2
255
255 0 0   0 255 0   0 0 255   255 255 0   255 0 255   0 255 255   30 30 30   220 220 220
10 20 30   40 50 60   70 80 90   100 110 120   130 140 150   160 170 180   190 200 210   240 240 240
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --output "$tmpdir/out.png" 16 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 16
    ;;
  usage-pngquant-posterize-three-png)
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
    ;;
  usage-pngquant-quality-high-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
4 2
255
255 0 0   0 255 0   0 0 255   255 255 0
255 0 255   0 255 255   40 40 40   220 220 220
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --quality=80-100 --output "$tmpdir/out.png" 8 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 8
    ;;
  usage-pngquant-speed-five-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
4 1
255
255 0 0   0 255 0   0 0 255   255 255 255
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --speed 5 --output "$tmpdir/out.png" 4 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 4
    ;;
  *)
    printf 'unknown libpng further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
