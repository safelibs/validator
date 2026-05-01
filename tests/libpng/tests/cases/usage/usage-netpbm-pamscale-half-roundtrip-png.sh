#!/usr/bin/env bash
# @testcase: usage-netpbm-pamscale-half-roundtrip-png
# @title: netpbm pamscale 0.5 halves PNG-derived dimensions
# @description: Decodes basn2c08.png to PPM, scales it by 0.5 with pamscale, re-encodes via pnmtopng, and confirms the resulting PNG is exactly 16x16 (half of the source 32x32) and parses as a valid PNG with the expected IHDR width/height.
# @timeout: 180
# @tags: usage, image, png, scaling, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.ppm"
pamfile "$tmpdir/in.ppm" | tee "$tmpdir/in.pamfile"
validator_assert_contains "$tmpdir/in.pamfile" '32 by 32'

pamscale 0.5 "$tmpdir/in.ppm" >"$tmpdir/half.ppm"
pamfile "$tmpdir/half.ppm" | tee "$tmpdir/half.pamfile"
validator_assert_contains "$tmpdir/half.pamfile" '16 by 16'

pnmtopng "$tmpdir/half.ppm" >"$tmpdir/half.png"
file "$tmpdir/half.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'
validator_assert_contains "$tmpdir/file" '16 x 16'

# Verify PNG signature and IHDR width/height match 16x16 at the byte level.
python3 - "$tmpdir/half.png" <<'PY'
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
w, h, _bd, _ct, _cm, _fm, _il = struct.unpack('>IIBBBBB', data[idx + 8:idx + 8 + length])
if (w, h) != (16, 16):
    raise SystemExit(f'expected 16x16 PNG, got {w}x{h}')
print(f'IHDR OK: {w}x{h}')
PY

# Round-trip back and confirm dims survive.
pngtopnm "$tmpdir/half.png" >"$tmpdir/half-rt.ppm"
pamfile "$tmpdir/half-rt.ppm" | tee "$tmpdir/half-rt.pamfile"
validator_assert_contains "$tmpdir/half-rt.pamfile" '16 by 16'
