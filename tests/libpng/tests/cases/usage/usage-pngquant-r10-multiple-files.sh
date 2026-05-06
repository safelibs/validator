#!/usr/bin/env bash
# @testcase: usage-pngquant-r10-multiple-files
# @title: pngquant processes multiple input PNGs in one invocation
# @description: Runs pngquant against two distinct synthetic PNGs in a single command and verifies both default -fs8.png outputs are emitted as valid PNG files.
# @timeout: 240
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for label in alpha bravo; do
  python3 - "$tmpdir/$label.ppm" "$label" <<'PY'
import sys
W, H = 24, 24
seed = sum(map(ord, sys.argv[2]))
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((((x + seed) * 5) & 0xff, ((y + seed) * 7) & 0xff, (x * y + seed) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
  pnmtopng "$tmpdir/$label.ppm" >"$tmpdir/$label.png"
done

pngquant --force 64 "$tmpdir/alpha.png" "$tmpdir/bravo.png"

for label in alpha bravo; do
  out="$tmpdir/$label-fs8.png"
  [[ -s "$out" ]] || { ls "$tmpdir" >&2; printf 'missing %s\n' "$out" >&2; exit 1; }
  file "$out" >"$tmpdir/file.txt"
  validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
done
