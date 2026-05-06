#!/usr/bin/env bash
# @testcase: usage-pngquant-r9-ext-suffix-output
# @title: pngquant --ext custom suffix output naming
# @description: Runs pngquant with a custom --ext suffix and verifies the resulting file is created at the suffixed path while the input remains.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/src.ppm" <<'PY'
import sys
W, H = 16, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((10, 200, 60))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/src.ppm" >"$tmpdir/src.png"

pngquant --ext '-r9.png' --force 256 "$tmpdir/src.png"

[[ -f "$tmpdir/src-r9.png" ]] || { ls "$tmpdir" >&2; printf 'missing suffixed file\n' >&2; exit 1; }
[[ -f "$tmpdir/src.png" ]] || { printf 'original file disappeared\n' >&2; exit 1; }

file "$tmpdir/src-r9.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
