#!/usr/bin/env bash
# @testcase: usage-pngquant-r12-speed-default-vs-eleven-distinct
# @title: pngquant --speed=1 differs from --speed=11 on the same input
# @description: Quantises the same noisy PNG with the slowest (--speed=1) and the fastest (--speed=11) quality settings at the same color count, and verifies the two output files are valid PNGs of identical dimensions but byte-distinct, confirming the speed knob influences the output bytes.
# @timeout: 180
# @tags: usage, image, png, speed
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import random, sys
random.seed(11)
W, H = 64, 64
b = bytearray()
for _ in range(W * H):
    b += bytes((random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --speed=1 --force --output "$tmpdir/slow.png" 32 "$tmpdir/in.png"
pngquant --speed=11 --force --output "$tmpdir/fast.png" 32 "$tmpdir/in.png"

for f in "$tmpdir/slow.png" "$tmpdir/fast.png"; do
  python3 - "$f" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h = struct.unpack('>II', data[16:24])
assert (w, h) == (64, 64), (w, h)
PY
done

if cmp -s "$tmpdir/slow.png" "$tmpdir/fast.png"; then
  printf 'expected --speed=1 and --speed=11 outputs to differ\n' >&2
  exit 1
fi
