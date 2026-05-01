#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-filter-none-png
# @title: netpbm pnmtopng -filter 0 (none)
# @description: Re-encodes basn2c08.png through pnmtopng with -filter 0 (force PNG filter type "None") and confirms every IDAT-decoded scanline begins with filter byte 0x00 while pixel content round-trips identically to the unfiltered re-encode.
# @timeout: 180
# @tags: usage, image, png, encoding
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.ppm"
pnmtopng -filter 0 "$tmpdir/in.ppm" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# Round-trip pixels must match input.
pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
cmp "$tmpdir/in.ppm" "$tmpdir/out.ppm"

# Walk the IDAT stream, decompress, and confirm every scanline filter byte is 0.
python3 - "$tmpdir/out.png" <<'PY'
import struct
import sys
import zlib

data = open(sys.argv[1], 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
assert data.startswith(sig)
idx = len(sig)
ihdr = None
idat = bytearray()
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    payload = data[idx + 8:idx + 8 + length]
    if ctype == 'IHDR':
        ihdr = struct.unpack('>IIBBBBB', payload)
    elif ctype == 'IDAT':
        idat += payload
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
w, h, depth, ctype_color, comp, filt, interlace = ihdr
if interlace != 0:
    raise SystemExit('expected non-interlaced output')
samples = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype_color]
bpp = max(1, samples * depth // 8)
stride = 1 + (w * samples * depth + 7) // 8
raw = zlib.decompress(bytes(idat))
if len(raw) < stride * h:
    raise SystemExit(f'short raw stream {len(raw)} < {stride*h}')
filters = [raw[i * stride] for i in range(h)]
non_zero = [(i, f) for i, f in enumerate(filters) if f != 0]
if non_zero:
    raise SystemExit(f'expected all filter bytes 0, got {non_zero[:5]}')
PY
