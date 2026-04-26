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
    data = open(path, "rb").read()
    idx = 0

    def skip_ws():
        nonlocal idx
        while idx < len(data):
            byte = data[idx]
            if byte in b" \t\r\n":
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
        while idx < len(data) and data[idx] not in b" \t\r\n":
            idx += 1
        return data[start:idx]

    magic = token()
    if magic not in (b"P5", b"P6"):
        raise SystemExit(f"unsupported netpbm magic: {magic!r}")

    width = int(token())
    height = int(token())
    maxval = int(token())
    if maxval != 255:
        raise SystemExit(f"unexpected maxval: {maxval}")

    if idx < len(data) and data[idx] in b" \t\r\n":
        if data[idx] == 13 and idx + 1 < len(data) and data[idx + 1] == 10:
            idx += 2
        else:
            idx += 1
    payload = list(data[idx:])
    channels = 1 if magic == b"P5" else 3
    expected_len = width * height * channels
    if len(payload) != expected_len:
        raise SystemExit(f"unexpected payload length {len(payload)} != {expected_len}")
    return width, height, channels, payload


command = sys.argv[1]
if command == "values":
    path = sys.argv[2]
    width = int(sys.argv[3])
    height = int(sys.argv[4])
    channels = int(sys.argv[5])
    expected = ast.literal_eval(sys.argv[6])
    actual = read_image(path)
    if actual[:3] != (width, height, channels):
        raise SystemExit(f"unexpected image shape: {actual[:3]} != {(width, height, channels)}")
    if actual[3] != expected:
        raise SystemExit(f"unexpected payload: {actual[3]} != {expected}")
elif command == "unique-rgb-max":
    path = sys.argv[2]
    max_colors = int(sys.argv[3])
    width, height, channels, payload = read_image(path)
    if channels not in (1, 3):
        raise SystemExit(f"expected grayscale or RGB image, found {channels} channels")
    colors = {tuple(payload[index:index + channels]) for index in range(0, len(payload), channels)}
    if len(colors) > max_colors:
        raise SystemExit(f"too many colors: {len(colors)} > {max_colors}")
elif command == "unique-gray-max":
    path = sys.argv[2]
    max_values = int(sys.argv[3])
    width, height, channels, payload = read_image(path)
    if channels != 1:
        raise SystemExit(f"expected grayscale image, found {channels} channels")
    values = set(payload)
    if len(values) > max_values:
        raise SystemExit(f"too many grayscale values: {len(values)} > {max_values}")
else:
    raise SystemExit(f"unknown netpbm assertion command: {command}")
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
  usage-netpbm-pnmflip-topbottom-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
2 2
255
10 20
30 40
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/from.png.pgm"
    pnmflip -topbottom "$tmpdir/from.png.pgm" >"$tmpdir/flipped.pgm"
    pnmtopng "$tmpdir/flipped.pgm" >"$tmpdir/out.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 2 1 '[30, 40, 10, 20]'
    ;;
  usage-netpbm-pnmcut-corner-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
4 4
255
1 2 3 4
5 6 7 8
9 10 11 12
13 14 15 16
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/from.png.pgm"
    pnmcut 1 1 2 3 "$tmpdir/from.png.pgm" >"$tmpdir/cut.pgm"
    pnmtopng "$tmpdir/cut.pgm" >"$tmpdir/out.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 3 1 '[6, 7, 10, 11, 14, 15]'
    ;;
  usage-netpbm-pnmscale-double-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
1 1
255
77
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/from.png.pgm"
    pnmscale 2 "$tmpdir/from.png.pgm" >"$tmpdir/scaled.pgm"
    pnmtopng "$tmpdir/scaled.pgm" >"$tmpdir/out.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 2 1 '[77, 77, 77, 77]'
    ;;
  usage-netpbm-pamchannel-green-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 1
255
10 20 30   40 50 60
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngtopam "$tmpdir/input.png" >"$tmpdir/from.png.pam"
    pamchannel -infile="$tmpdir/from.png.pam" 1 >"$tmpdir/green.pam"
    pamtopnm -assume "$tmpdir/green.pam" >"$tmpdir/green.pgm"
    pnmtopng "$tmpdir/green.pgm" >"$tmpdir/out.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[20, 50]'
    ;;
  usage-netpbm-pnmfile-roundtrip-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
2 2
255
255 0 0   0 255 0
0 0 255   255 255 255
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/out.ppm"
    assert_values "$tmpdir/out.ppm" 2 2 3 '[255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255]'
    ;;
  usage-pngquant-colors-two-png)
    cat >"$tmpdir/input.ppm" <<'EOF'
P3
4 1
255
255 0 0   0 255 0   0 0 255   255 255 255
EOF
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --output "$tmpdir/out.png" 2 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 2
    ;;
  usage-pngquant-quality-low-png)
    python3 - <<'PY' "$tmpdir/input.ppm"
import sys
path = sys.argv[1]
with open(path, "w", encoding="ascii") as handle:
    handle.write("P3\n32 1\n255\n")
    for value in range(32):
        red = value * 8
        green = 255 - red
        blue = (value * 17) % 256
        handle.write(f"{red} {green} {blue} ")
PY
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --quality=1-20 --output "$tmpdir/out.png" 16 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 16
    ;;
  usage-pngquant-speed-eleven-png)
    python3 - <<'PY' "$tmpdir/input.ppm"
import sys
path = sys.argv[1]
with open(path, "w", encoding="ascii") as handle:
    handle.write("P3\n12 1\n255\n")
    for value in range(12):
        red = value * 20
        green = 255 - value * 10
        blue = value * 7
        handle.write(f"{red} {green} {blue} ")
PY
    pnmtopng "$tmpdir/input.ppm" >"$tmpdir/input.png"
    pngquant --force --speed 11 --output "$tmpdir/out.png" 4 "$tmpdir/input.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
    assert_unique_rgb_max "$tmpdir/out.ppm" 4
    ;;
  usage-netpbm-pnminvert-png)
    cat >"$tmpdir/input.pgm" <<'EOF'
P2
3 1
255
0 64 255
EOF
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" >"$tmpdir/from.png.pgm"
    pnminvert "$tmpdir/from.png.pgm" >"$tmpdir/inverted.pgm"
    pnmtopng "$tmpdir/inverted.pgm" >"$tmpdir/out.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 3 1 1 '[255, 191, 0]'
    ;;
  usage-pngquant-posterize-two-png)
    python3 - <<'PY' "$tmpdir/input.pgm"
import sys
path = sys.argv[1]
with open(path, "w", encoding="ascii") as handle:
    handle.write("P2\n256 1\n255\n")
    for value in range(256):
        handle.write(f"{value} ")
PY
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngquant --force --posterize 2 --output "$tmpdir/out.png" 256 "$tmpdir/input.png"
    pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
    pamchannel -infile="$tmpdir/out.pam" 0 >"$tmpdir/out.gray.pam"
    pamtopnm -assume "$tmpdir/out.gray.pam" >"$tmpdir/out.pgm"
    assert_unique_gray_max "$tmpdir/out.pgm" 64
    ;;
  *)
    printf 'unknown libpng additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
