#!/usr/bin/env bash
# @testcase: usage-netpbm-pamdepth-16bit-pamtopng-png
# @title: netpbm pamdepth 65535 + pamtopng yields 16-bit PNG
# @description: Decodes basn2c08.png to a maxval-255 PPM, promotes it to maxval 65535 via pamdepth, encodes through pamtopng, and confirms the resulting PNG IHDR reports bit depth 16 (rather than 8) -- exercising libpng's 16-bit RGB write path through the netpbm toolchain.
# @timeout: 180
# @tags: usage, image, png, bitdepth, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.ppm"
pamfile "$tmpdir/in.ppm" | tee "$tmpdir/in.pamfile"
validator_assert_contains "$tmpdir/in.pamfile" 'maxval 255'

pamdepth 65535 "$tmpdir/in.ppm" >"$tmpdir/16.ppm"
pamfile "$tmpdir/16.ppm" | tee "$tmpdir/16.pamfile"
validator_assert_contains "$tmpdir/16.pamfile" 'maxval 65535'

pamtopng "$tmpdir/16.ppm" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'
validator_assert_contains "$tmpdir/file" '16-bit/color RGB'

python3 - "$tmpdir/out.png" <<'PY'
import struct
import sys

data = open(sys.argv[1], 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
if data[:8] != sig:
    raise SystemExit(f'bad signature: {data[:8]!r}')
idx = 8
(length,) = struct.unpack('>I', data[idx:idx + 4])
ctype = data[idx + 4:idx + 8]
if ctype != b'IHDR':
    raise SystemExit(f'expected IHDR first, got {ctype!r}')
w, h, bd, ct, cm, fm, il = struct.unpack('>IIBBBBB', data[idx + 8:idx + 8 + length])
if (w, h) != (32, 32):
    raise SystemExit(f'unexpected dims: {w}x{h}')
if bd != 16:
    raise SystemExit(f'expected bit depth 16, got {bd}')
if ct != 2:
    raise SystemExit(f'expected color type 2 (RGB), got {ct}')
print(f'IHDR OK: {w}x{h} bd={bd} ct={ct}')
PY
