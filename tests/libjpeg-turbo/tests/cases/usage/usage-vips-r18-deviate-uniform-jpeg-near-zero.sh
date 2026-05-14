#!/usr/bin/env bash
# @testcase: usage-vips-r18-deviate-uniform-jpeg-near-zero
# @title: vips deviate on a solid-gray JPEG returns a small positive standard deviation
# @description: Encodes a 16x16 solid-gray-128 PGM as a grayscale JPEG via vips jpegsave then runs vips deviate on it and asserts the printed standard deviation, truncated to an integer, is less than 8 (libjpeg-turbo introduces only small per-pixel drift on a uniform image), exercising the vips deviate reducer on a near-uniform input.
# @timeout: 180
# @tags: usage, vips, jpeg, deviate, r18
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
raw=$(vips deviate "$tmpdir/in.jpg")
val=${raw%%.*}
# Negative deviations shouldn't happen, but allow defensive parse.
val=${val#-}
if (( val >= 8 )); then
  printf 'expected deviate < 8 on uniform input, got %s\n' "$raw" >&2
  exit 1
fi
