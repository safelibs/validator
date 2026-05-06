#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-r9-filter-up-png
# @title: pnmtopng -filter up emits valid PNG
# @description: Encodes a PPM through pnmtopng -filter up and verifies the output is recognized as PNG image data and reopens with the expected dimensions.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a tiny PPM.
python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 8, 6
with open(sys.argv[1], "wb") as f:
    f.write(f"P6\n{w} {h}\n255\n".encode())
    f.write(bytes((x*30 % 256, y*30 % 256, (x+y) % 256) for y in range(h) for x in range(w)
                  for _ in range(1))[:w*h*3] if False else b"".join(
        bytes([x*30 % 256, y*30 % 256, (x+y) % 256]) for y in range(h) for x in range(w)))
PY

# pnmtopng's -filter accepts the libpng filter index: 0=NONE, 1=SUB, 2=UP, ...
pnmtopng -filter 2 "$tmpdir/in.ppm" >"$tmpdir/out.png"
file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'

python3 - "$tmpdir/out.png" <<'PY'
import sys, struct
data = open(sys.argv[1], "rb").read()
assert data.startswith(b'\x89PNG\r\n\x1a\n')
# Read IHDR width/height.
ihdr = data[16:24]
w, h = struct.unpack('>II', ihdr)
assert (w, h) == (8, 6), (w, h)
PY
