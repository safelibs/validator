#!/usr/bin/env bash
# @testcase: usage-vips-r17-avg-solid-color-equals-input-value
# @title: vips avg on a solid-128 JPEG returns a value close to 128
# @description: Encodes a 16x16 solid-gray-128 PGM as a grayscale JPEG, then runs vips avg on it and asserts the printed numeric average is between 120 and 136 inclusive (libjpeg-turbo quantisation introduces small drift around the original 128), exercising the avg reducer over a uniform image.
# @timeout: 180
# @tags: usage, vips, jpeg, avg
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.pgm"
import sys
W, H = 16, 16
data = bytes([128] * (W * H))
open(sys.argv[1], 'wb').write(f'P5\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.pgm" "$tmpdir/in.jpg" --Q 95
raw=$(vips avg "$tmpdir/in.jpg")
val=${raw%%.*}
if (( val < 120 || val > 136 )); then
  printf 'expected avg in [120,136], got %s\n' "$raw" >&2
  exit 1
fi
