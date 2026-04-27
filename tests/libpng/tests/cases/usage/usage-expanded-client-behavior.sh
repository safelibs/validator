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
        raise SystemExit('unexpected shape')
    if payload != expected:
        raise SystemExit(f'unexpected payload {payload} != {expected}')
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
  python3 "$tmpdir/netpbm_assert.py" values "$1" "$2" "$3" "$4" "$5"
}
assert_maxval() {
  python3 "$tmpdir/netpbm_assert.py" maxval "$1" "$2"
}
assert_unique_rgb_max() {
  python3 "$tmpdir/netpbm_assert.py" unique-rgb-max "$1" "$2"
}

case "$case_id" in
  usage-netpbm-pnmflip-leftright-png-generated)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 1
255
10 20
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmflip -leftright "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[20, 10]'
    ;;
  usage-netpbm-pnmflip-topbottom-png-generated)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
1 2
255
10
20
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmflip -topbottom "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 1 2 1 '[20, 10]'
    ;;
  usage-netpbm-pamflip-cw-png-generated)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 2
255
10 20
30 40
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pamflip -cw "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 2 1 '[30, 10, 40, 20]'
    ;;
  usage-netpbm-pamchannel-red-png-generated)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 1
255
10 40 70   20 50 80
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.ppm"
    pamchannel 0 <"$tmpdir/raw.ppm" >"$tmpdir/out.pam"
    pamtopnm -assume "$tmpdir/out.pam" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[10, 20]'
    ;;
  usage-netpbm-pnmdepth-15-png-generated)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
1 1
255
255
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmdepth 15 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_maxval "$tmpdir/out.pgm" 15
    ;;
  usage-netpbm-pnminvert-png-generated)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 1
255
10 200
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnminvert "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[245, 55]'
    ;;
  usage-netpbm-pnmscale-double-png-generated)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
1 1
255
33
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmscale 2 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 2 1 '[33, 33, 33, 33]'
    ;;
  usage-pngquant-colors-eight-png-generated)
    python3 - <<'PYCASE' "$tmpdir/input.ppm"
import sys
with open(sys.argv[1], 'w', encoding='ascii') as handle:
    handle.write('P3\n4 4\n255\n')
    for value in range(16):
        handle.write(f'{value * 10 % 256} {value * 30 % 256} {value * 50 % 256} ')
PYCASE
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --output "$tmpdir/out.png" 8 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 8
    ;;
  usage-pngquant-speed-one-png-generated)
    python3 - <<'PYCASE' "$tmpdir/input.ppm"
import sys
with open(sys.argv[1], 'w', encoding='ascii') as handle:
    handle.write('P3\n4 4\n255\n')
    for value in range(16):
        handle.write(f'{value * 15 % 256} {value * 35 % 256} {value * 55 % 256} ')
PYCASE
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --speed 1 --output "$tmpdir/out.png" 8 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 8
    ;;
  usage-pngquant-quality-low-png-generated)
    python3 - <<'PYCASE' "$tmpdir/input.ppm"
import sys
with open(sys.argv[1], 'w', encoding='ascii') as handle:
    handle.write('P3\n4 4\n255\n')
    for value in range(16):
        handle.write(f'{value * 17 % 256} {value * 37 % 256} {value * 57 % 256} ')
PYCASE
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --quality=0-60 --output "$tmpdir/out.png" 8 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 8
    ;;
  *)
    printf 'unknown libpng expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
