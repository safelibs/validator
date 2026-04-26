#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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
elif cmd == 'unique-gray-max':
    width, height, channels, payload = read_image(sys.argv[2])
    if channels != 1:
        raise SystemExit('expected grayscale image')
    if len(set(payload)) > int(sys.argv[3]):
        raise SystemExit('too many grayscale values')
else:
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

case "$case_id" in
  usage-netpbm-pnmflip-leftright-generated-png)
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
  usage-netpbm-pnmflip-transpose-png)
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
    pnmflip -transpose "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 3 2 1 '[1, 3, 5, 2, 4, 6]'
    ;;
  usage-netpbm-pnmcut-bottom-row-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
3 3
255
1 2 3
4 5 6
7 8 9
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmcut 0 2 3 1 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 3 1 1 '[7, 8, 9]'
    ;;
  usage-netpbm-pnmscale-triple-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
1 1
255
77
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/raw.pgm"
    pnmscale 3 "$tmpdir/raw.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 3 3 1 '[77, 77, 77, 77, 77, 77, 77, 77, 77]'
    ;;
  usage-netpbm-pamchannel-red-generated-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 1
255
10 20 30   40 50 60
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngtopam "$tmpdir/input.png" >"$tmpdir/raw.pam"
    pamchannel -infile="$tmpdir/raw.pam" 0 >"$tmpdir/red.pam"
    pamtopnm -assume "$tmpdir/red.pam" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[10, 40]'
    ;;
  usage-netpbm-pamchannel-blue-generated-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 1
255
10 20 30   40 50 60
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngtopam "$tmpdir/input.png" >"$tmpdir/raw.pam"
    pamchannel -infile="$tmpdir/raw.pam" 2 >"$tmpdir/blue.pam"
    pamtopnm -assume "$tmpdir/blue.pam" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[30, 60]'
    ;;
  usage-pngquant-colors-three-png)
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
    ;;
  usage-pngquant-posterize-one-png)
    python3 - <<'PY' "$tmpdir/input.pgm"
import sys
with open(sys.argv[1], 'w', encoding='ascii') as handle:
    handle.write('P2\n32 1\n255\n')
    for value in range(32):
        handle.write(f'{value * 8} ')
PY
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngquant --force --nofs --posterize 1 --output "$tmpdir/out.png" 256 "$tmpdir/input.png"
    validator_require_file "$tmpdir/out.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.pnm"
    test -s "$tmpdir/out.pnm"
    ;;
  usage-pngquant-quality-mid-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
8 1
255
255 0 0   0 255 0   0 0 255   255 255 0   255 0 255   0 255 255   30 30 30   220 220 220
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --quality=40-90 --output "$tmpdir/out.png" 8 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 8
    ;;
  usage-pngquant-speed-three-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
4 1
255
255 0 0   0 255 0   0 0 255   255 255 255
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --speed 3 --output "$tmpdir/out.png" 4 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 4
    ;;
  *)
    printf 'unknown libpng even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
