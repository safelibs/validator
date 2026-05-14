#!/usr/bin/env bash
# @testcase: usage-vips-r18-min-solid-color-jpeg
# @title: vips min on a solid-64 grayscale JPEG returns a value close to 64
# @description: Encodes a 16x16 solid-gray-64 PGM as a grayscale JPEG via vips jpegsave then runs vips min on it and asserts the printed numeric minimum is in the inclusive range [56, 72] (libjpeg-turbo quantisation drift around 64), exercising the vips min reducer over a uniform JPEG image.
# @timeout: 180
# @tags: usage, vips, jpeg, min, r18
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.pgm"
import sys
W, H = 16, 16
data = bytes([64] * (W * H))
open(sys.argv[1], 'wb').write(f'P5\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.pgm" "$tmpdir/in.jpg" --Q 95
raw=$(vips min "$tmpdir/in.jpg")
val=${raw%%.*}
if (( val < 56 || val > 72 )); then
  printf 'expected min in [56,72], got %s\n' "$raw" >&2
  exit 1
fi
