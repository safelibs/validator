#!/usr/bin/env bash
# @testcase: usage-pngquant-speed-nine-png
# @title: pngquant --speed 9 mid-fast preset
# @description: Quantizes basn2c08.png with pngquant --speed 9 (uncovered intermediate level between the existing speed 8 and speed 10 cases), confirms the output decodes at 32x32, and verifies the result PNG has color type 3 (indexed) with no more than 256 PLTE entries.
# @timeout: 180
# @tags: usage, image, png, quantization
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --speed 9 --force --output "$tmpdir/out.png" 256 "$png"
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
ihdr_payload = None
plte_len = None
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    if ctype == 'IHDR':
        ihdr_payload = payload
    elif ctype == 'PLTE':
        plte_len = length
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
w, h, depth, ctype_color, comp, filt, interlace = struct.unpack('>IIBBBBB', ihdr_payload)
if ctype_color != 3:
    raise SystemExit(f'expected indexed color type after pngquant, got {ctype_color}')
if plte_len is None:
    raise SystemExit('missing PLTE')
entries = plte_len // 3
if entries > 256:
    raise SystemExit(f'PLTE entries exceed 256: {entries}')
print(f'speed-9 ok ctype={ctype_color} entries={entries}')
PY
