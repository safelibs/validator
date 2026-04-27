#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  usage-netpbm-pnminvert-rgb-png-roundtrip)
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
    ;;
  usage-netpbm-pnmflip-rotate180-rgb-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 2
255
10 20 30   40 50 60
70 80 90   100 110 120
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.ppm"
    pnmflip -rotate180 "$tmpdir/raw.ppm" >"$tmpdir/out.ppm"
    assert_values "$tmpdir/out.ppm" 2 2 3 '[100, 110, 120, 70, 80, 90, 40, 50, 60, 10, 20, 30]'
    ;;
  usage-netpbm-pamflip-ccw-grayscale-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 2
255
10 20
30 40
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pamflip -ccw "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 2 1 '[20, 40, 10, 30]'
    ;;
  usage-netpbm-pnmcat-leftright-png-generated)
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
    ;;
  usage-netpbm-pnmcat-topbottom-png-generated)
    cat >"$tmpdir/top.pgm" <<'EOF'
P2
1 1
255
50
EOF
    cat >"$tmpdir/bot.pgm" <<'EOF'
P2
1 1
255
150
EOF
    pnmtopng "$tmpdir/top.pgm" >"$tmpdir/top.png"
    pnmtopng "$tmpdir/bot.pgm" >"$tmpdir/bot.png"
    pngtopnm "$tmpdir/top.png" >"$tmpdir/top_raw.pgm"
    pngtopnm "$tmpdir/bot.png" >"$tmpdir/bot_raw.pgm"
    pnmcat -tb "$tmpdir/top_raw.pgm" "$tmpdir/bot_raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 1 2 1 '[50, 150]'
    ;;
  usage-netpbm-pnmscale-half-png-generated)
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
    ;;
  usage-netpbm-pamchannel-green-png-generated)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 1
255
10 40 70   20 50 80
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.ppm"
    pamchannel 1 <"$tmpdir/raw.ppm" >"$tmpdir/out.pam"
    pamtopnm -assume "$tmpdir/out.pam" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[40, 50]'
    ;;
  usage-netpbm-pnmdepth-63-png-generated)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
1 1
255
255
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmdepth 63 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    python3 "$tmpdir/pgm_assert.py" maxval "$tmpdir/out.pgm" 63
    ;;
  usage-pngquant-colors-four-png-generated)
    python3 - <<'PYCASE' "$tmpdir/input.ppm"
import sys
with open(sys.argv[1], 'w', encoding='ascii') as handle:
    handle.write('P3\n4 4\n255\n')
    for value in range(16):
        handle.write(f'{value * 11 % 256} {value * 23 % 256} {value * 41 % 256} ')
PYCASE
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --output "$tmpdir/out.png" 4 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 4
    ;;
  usage-pngquant-nofs-png-generated)
    python3 - <<'PYCASE' "$tmpdir/input.ppm"
import sys
with open(sys.argv[1], 'w', encoding='ascii') as handle:
    handle.write('P3\n4 4\n255\n')
    for value in range(16):
        handle.write(f'{value * 13 % 256} {value * 27 % 256} {value * 47 % 256} ')
PYCASE
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --nofs --output "$tmpdir/out.png" 8 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 8
    ;;
  *)
    printf 'unknown libpng tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
