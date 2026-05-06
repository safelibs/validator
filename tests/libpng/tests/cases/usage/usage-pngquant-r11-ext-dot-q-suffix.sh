#!/usr/bin/env bash
# @testcase: usage-pngquant-r11-ext-dot-q-suffix
# @title: pngquant --ext .png --force converts in place
# @description: Uses the documented "--ext .png --force" combination to overwrite the input file with its quantised version, verifying the file remains a valid PNG and now decodes as a paletted colormap (proving the in-place conversion happened, not just a no-op).
# @timeout: 120
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/sample.ppm" <<'PY'
import sys
W, H = 32, 32
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 8) & 0xff, (y * 8) & 0xff, ((x + y) * 4) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/sample.ppm" >"$tmpdir/sample.png"

# Source PNG is truecolor (color type 2) before in-place conversion.
python3 - "$tmpdir/sample.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
_, _, _, color_type = struct.unpack('>IIBB', data[16:26])
assert color_type == 2, color_type
PY

(cd "$tmpdir" && pngquant --ext .png --force 16 sample.png)

[[ -f "$tmpdir/sample.png" ]] || { ls "$tmpdir" >&2; exit 1; }

file "$tmpdir/sample.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
validator_assert_contains "$tmpdir/file.txt" 'colormap'

# Confirm in-place conversion changed the color type from truecolor to palette.
python3 - "$tmpdir/sample.png" <<'PY'
import sys, struct
data = open(sys.argv[1], 'rb').read()
_, _, _, color_type = struct.unpack('>IIBB', data[16:26])
assert color_type == 3, color_type
PY
