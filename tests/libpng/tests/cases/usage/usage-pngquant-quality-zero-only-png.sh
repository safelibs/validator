#!/usr/bin/env bash
# @testcase: usage-pngquant-quality-zero-only-png
# @title: pngquant --quality 0 minimum-only floor
# @description: Quantizes basn2c08.png with --quality 0 (minimum-only floor of 0 with implicit max 100) and confirms pngquant emits a valid indexed PNG that still decodes at 32x32 -- this exercises the rarely-tested zero-floor branch of the min-max parser separate from the existing min-low-bound case.
# @timeout: 180
# @tags: usage, image, png, quantization
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --quality 0 --force --output "$tmpdir/out.png" 256 "$png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys

data = open(sys.argv[1], 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
assert data.startswith(sig)
idx = len(sig)
seen_ihdr = False
seen_idat = False
ctype_color = None
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    if ctype == 'IHDR':
        seen_ihdr = True
        _, _, _, ctype_color, _, _, _ = struct.unpack('>IIBBBBB', payload)
    elif ctype == 'IDAT':
        seen_idat = True
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if not (seen_ihdr and seen_idat):
    raise SystemExit('output PNG missing required chunks')
if ctype_color != 3:
    raise SystemExit(f'expected indexed color, got ctype={ctype_color}')
PY
