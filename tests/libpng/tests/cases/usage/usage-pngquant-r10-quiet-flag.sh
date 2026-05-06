#!/usr/bin/env bash
# @testcase: usage-pngquant-r10-quiet-flag
# @title: pngquant --quiet still emits the optimized PNG
# @description: Quantizes a synthetic PNG with --quiet to confirm the option suppresses status chatter while still producing a valid PNG file at the requested output path.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 16, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 16) & 0xff, (y * 16) & 0xff, ((x + y) * 8) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --quiet --force --output "$tmpdir/out.png" 64 "$tmpdir/in.png" >"$tmpdir/stdout.log" 2>"$tmpdir/stderr.log"

[[ -s "$tmpdir/out.png" ]]
[[ ! -s "$tmpdir/stdout.log" ]] || {
  printf '--quiet wrote to stdout:\n' >&2
  cat "$tmpdir/stdout.log" >&2
  exit 1
}
file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
