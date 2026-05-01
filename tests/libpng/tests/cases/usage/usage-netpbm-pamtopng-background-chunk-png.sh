#!/usr/bin/env bash
# @testcase: usage-netpbm-pamtopng-background-chunk-png
# @title: netpbm pamtopng -background emits bKGD chunk
# @description: Re-encodes basn2c08.png with pamtopng -background=red, walks the resulting PNG chunk stream to confirm a 6-byte bKGD chunk is present (RGB color type stores three big-endian uint16 components), and confirms the encoded background's red channel is non-zero while green and blue are zero. pamtopng emits the channel values at the source bit-depth scale (here 8-bit, i.e. R=255), not the spec's nominal 16-bit max, so we just check for an unmistakably-red triple.
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
pamtopng -background=red "$tmpdir/in.ppm" >"$tmpdir/out.png"
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
bkgd_payload = None
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    chunks.append(ctype)
    if ctype == 'bKGD':
        bkgd_payload = data[idx + 8:idx + 8 + length]
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if 'bKGD' not in chunks:
    raise SystemExit(f'expected bKGD chunk, got {chunks}')
# RGB color type: 6 bytes (R,G,B as big-endian 16-bit).
if len(bkgd_payload) != 6:
    raise SystemExit(f'bKGD payload must be 6 bytes for RGB, got {len(bkgd_payload)}')
r, g, b = struct.unpack('>HHH', bkgd_payload)
# pamtopng on an 8-bit input writes R=255 (max for 8-bit) into the uint16 field.
if r == 0 or g != 0 or b != 0:
    raise SystemExit(f'expected red bKGD (R>0,0,0), got ({r},{g},{b})')
print(f'bKGD OK, color=({r},{g},{b})')
PY
