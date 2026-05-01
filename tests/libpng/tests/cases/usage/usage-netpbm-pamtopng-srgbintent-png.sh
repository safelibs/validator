#!/usr/bin/env bash
# @testcase: usage-netpbm-pamtopng-srgbintent-png
# @title: netpbm pamtopng -srgbintent emits sRGB chunk
# @description: Decodes basn2c08.png to PPM, re-encodes with pamtopng -srgbintent=perceptual, and parses the resulting PNG to confirm an sRGB chunk is present with a 1-byte payload equal to 0 (perceptual rendering intent).
# @timeout: 180
# @tags: usage, image, png, metadata, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.ppm"
pamtopng -srgbintent=perceptual "$tmpdir/in.ppm" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

python3 - "$tmpdir/out.png" <<'PY'
import struct
import sys

data = open(sys.argv[1], 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
if not data.startswith(sig):
    raise SystemExit('not a PNG signature')
idx = len(sig)
chunks = []
srgb_payload = None
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    chunks.append(ctype)
    if ctype == 'sRGB':
        srgb_payload = data[idx + 8:idx + 8 + length]
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if 'sRGB' not in chunks:
    raise SystemExit(f'expected sRGB chunk, got {chunks}')
if len(srgb_payload) != 1:
    raise SystemExit(f'sRGB payload must be 1 byte, got {len(srgb_payload)}')
if srgb_payload[0] != 0:
    raise SystemExit(f'expected perceptual intent (0), got {srgb_payload[0]}')
print(f'sRGB chunk OK, intent={srgb_payload[0]}')
PY

# Pixel content must still round-trip identically.
pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
cmp "$tmpdir/in.ppm" "$tmpdir/out.ppm"
