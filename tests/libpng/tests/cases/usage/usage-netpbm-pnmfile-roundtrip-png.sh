#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmfile-roundtrip-png
# @title: netpbm pnmfile round trip PNG
# @description: Round-trips a PNG fixture through PNM conversion tools and verifies pnmfile reports valid image dimensions afterward.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmfile-roundtrip-png"
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
