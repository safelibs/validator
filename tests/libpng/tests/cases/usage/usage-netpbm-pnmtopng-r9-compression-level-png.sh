#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-r9-compression-level-png
# @title: pnmtopng -compression 9 emits PNG
# @description: Encodes a PPM with pnmtopng -compression 9 and verifies that the output is a PNG file and is generally smaller than -compression 0 output.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 64, 64
with open(sys.argv[1], "wb") as f:
    f.write(f"P6\n{w} {h}\n255\n".encode())
    # Highly compressible solid-colour image.
    f.write(b"\x40\x80\xc0" * (w * h))
PY

pnmtopng -compression 9 "$tmpdir/in.ppm" >"$tmpdir/c9.png"
pnmtopng -compression 0 "$tmpdir/in.ppm" >"$tmpdir/c0.png"

file "$tmpdir/c9.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'

s9=$(stat -c '%s' "$tmpdir/c9.png")
s0=$(stat -c '%s' "$tmpdir/c0.png")
[[ "$s9" -lt "$s0" ]] || { printf 'expected -compression 9 (%s) smaller than 0 (%s)\n' "$s9" "$s0" >&2; exit 1; }
