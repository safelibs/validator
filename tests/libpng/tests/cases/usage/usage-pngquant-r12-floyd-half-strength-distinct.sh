#!/usr/bin/env bash
# @testcase: usage-pngquant-r12-floyd-half-strength-distinct
# @title: pngquant --floyd=0.5 produces a different output than --nofs
# @description: Quantises a synthetic gradient PNG twice — once with --floyd=0.5 (half-strength Floyd-Steinberg) and once with --nofs (no dithering) — at the same color count, and asserts the two output files have different byte contents while both being valid paletted PNGs of the same dimensions.
# @timeout: 180
# @tags: usage, image, png, dither
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 48, 48
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 5 & 0xff, y * 5 & 0xff, ((x + y) * 3) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --floyd=0.5 --force --output "$tmpdir/dither.png" 16 "$tmpdir/in.png"
pngquant --nofs --force --output "$tmpdir/nofs.png" 16 "$tmpdir/in.png"

# Both must be valid PNGs of the same dimensions.
for f in "$tmpdir/dither.png" "$tmpdir/nofs.png"; do
  python3 - "$f" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, _, ct = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (48, 48), (w, h)
assert ct == 3, ct
PY
done

# But the two files must differ — dithering distributes quantisation error.
if cmp -s "$tmpdir/dither.png" "$tmpdir/nofs.png"; then
  printf 'expected --floyd=0.5 and --nofs outputs to differ\n' >&2
  exit 1
fi
