#!/usr/bin/env bash
# @testcase: usage-pngquant-r19-output-equals-input-without-force-fails
# @title: pngquant refuses to overwrite an existing output file without --force
# @description: Quantises a PNG once to a known output path, then re-runs pngquant targeting the same output without --force and asserts pngquant exits non-zero, pinning the safety check that prevents accidental overwrite.
# @timeout: 120
# @tags: usage, image, png, pngquant, force, r19
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 12, 12
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 18) & 0xff, (y * 19) & 0xff, ((x + y) * 9) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

pngquant --force --output "$tmpdir/out.png" 16 "$tmpdir/in.png"
validator_require_file "$tmpdir/out.png"

# Re-run without --force should fail
if pngquant --output "$tmpdir/out.png" 16 "$tmpdir/in.png" 2>"$tmpdir/err.log"; then
  printf 'pngquant unexpectedly succeeded overwriting without --force\n' >&2
  exit 1
fi
