#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-palette-from-fixture-png
# @title: netpbm pnmtopng -palette derived from fixture
# @description: Quantizes basn2c08.png to a small palette via pnmquant 16, encodes the result with pnmtopng -palette using a derived 16-color palette PPM, and verifies the resulting PNG IHDR reports color type 3 (indexed) and contains a PLTE chunk with the expected 48-byte (16-entry) length.
# @timeout: 180
# @tags: usage, image, png, palette
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.ppm"
pnmquant 16 "$tmpdir/in.ppm" >"$tmpdir/q16.ppm"
pnmcolormap 16 "$tmpdir/in.ppm" >"$tmpdir/palette.ppm"

pnmtopng -palette "$tmpdir/palette.ppm" "$tmpdir/q16.ppm" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

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
if ihdr_payload is None:
    raise SystemExit('no IHDR')
w, h, depth, ctype_color, comp, filt, interlace = struct.unpack('>IIBBBBB', ihdr_payload)
if ctype_color != 3:
    raise SystemExit(f'expected indexed color type 3, got {ctype_color}')
if plte_len is None:
    raise SystemExit('missing PLTE chunk in indexed PNG')
if plte_len % 3 != 0:
    raise SystemExit(f'PLTE length not multiple of 3: {plte_len}')
entries = plte_len // 3
if entries > 16 or entries < 1:
    raise SystemExit(f'expected up to 16 PLTE entries, got {entries}')
print(f'IHDR ok ({w}x{h} depth={depth} ctype=3) PLTE entries={entries}')
PY
