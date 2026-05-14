#!/usr/bin/env bash
# @testcase: usage-vips-r18-max-solid-color-jpeg
# @title: vips max on a solid-200 grayscale JPEG returns a value close to 200
# @description: Encodes a 16x16 solid-gray-200 PGM as a grayscale JPEG via vips jpegsave then runs vips max on it and asserts the printed numeric maximum is in the inclusive range [192, 208] (libjpeg-turbo quantisation drift around 200), exercising the vips max reducer over a uniform JPEG image.
# @timeout: 180
# @tags: usage, vips, jpeg, max, r18
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.pgm"
import sys
W, H = 16, 16
data = bytes([200] * (W * H))
open(sys.argv[1], 'wb').write(f'P5\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.pgm" "$tmpdir/in.jpg" --Q 95
raw=$(vips max "$tmpdir/in.jpg")
val=${raw%%.*}
if (( val < 192 || val > 208 )); then
  printf 'expected max in [192,208], got %s\n' "$raw" >&2
  exit 1
fi
