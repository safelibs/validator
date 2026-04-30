#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmscale-double-png
# @title: netpbm double scale PNG
# @description: Doubles a PNG fixture through PNM scaling tools and verifies the reconstructed PNG output.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmscale-double-png"
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
