#!/usr/bin/env bash
# @testcase: usage-pngquant-r17-strip-removes-ancillary-text-chunk
# @title: pngquant --strip removes an ancillary tEXt chunk from the output PNG
# @description: Builds a 32x32 gradient PNG with a tEXt chunk via pnmtopng -text, runs pngquant --strip, and asserts the output PNG no longer contains the tEXt chunk type, pinning the metadata-strip behavior on Ubuntu 24.04 pngquant 2.18.
# @timeout: 120
# @tags: usage, image, png, pngquant, strip
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 32, 32
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 7) & 0xff, (y * 9) & 0xff, ((x + y) * 5) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

printf 'Comment R17-tag-payload-for-strip-test\n' >"$tmpdir/text.txt"
pnmtopng -text "$tmpdir/text.txt" "$tmpdir/in.ppm" >"$tmpdir/in.png"

# Sanity: input contains tEXt
grep -aFq 'tEXt' "$tmpdir/in.png" \
  || { printf 'expected tEXt in fixture\n' >&2; exit 1; }

pngquant --force --strip --output "$tmpdir/out.png" 64 "$tmpdir/in.png"
validator_require_file "$tmpdir/out.png"

if grep -aFq 'tEXt' "$tmpdir/out.png"; then
  printf 'tEXt chunk survived --strip\n' >&2
  exit 1
fi
