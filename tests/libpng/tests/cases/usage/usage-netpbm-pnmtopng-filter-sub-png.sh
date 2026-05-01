#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-filter-sub-png
# @title: netpbm pnmtopng -sub restricts row filter
# @description: Re-encodes basn2c08.png with pnmtopng -sub (only Sub filter permitted), decompresses the resulting IDAT stream and confirms every scanline filter byte is either 0 (None) or 1 (Sub) -- pnmtopng documents -sub as "permits the Sub filter" and the encoder must not emit Up/Average/Paeth filter bytes when only Sub is allowed. Pixel content must round-trip identically.
# @timeout: 180
# @tags: usage, image, png, encoding, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopnm "$png" >"$tmpdir/in.ppm"
pnmtopng -sub "$tmpdir/in.ppm" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# Round-trip pixels must match input.
pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
cmp "$tmpdir/in.ppm" "$tmpdir/out.ppm"

# Decompress IDAT and confirm every per-scanline filter byte is in {0, 1}.
python3 - "$tmpdir/out.png" <<'PY'
import struct
import sys
import zlib

data = open(sys.argv[1], 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
if not data.startswith(sig):
    raise SystemExit('not a PNG signature')
idx = len(sig)
ihdr = None
idat = bytearray()
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8]
    payload = data[idx + 8:idx + 8 + length]
    if ctype == b'IHDR':
        ihdr = struct.unpack('>IIBBBBB', payload)
    elif ctype == b'IDAT':
        idat.extend(payload)
    idx += 8 + length + 4
    if ctype == b'IEND':
        break

w, h, bd, ct, _cm, _fm, il = ihdr
if il != 0:
    raise SystemExit(f'expected non-interlaced output, got interlace={il}')
# RGB color type=2, bd=8 -> 3 bytes per pixel.
if (bd, ct) != (8, 2):
    raise SystemExit(f'unexpected IHDR (bd,ct)=({bd},{ct})')
bpp = 3
stride = 1 + w * bpp  # 1 filter byte + scanline

raw = zlib.decompress(bytes(idat))
if len(raw) != h * stride:
    raise SystemExit(f'expected {h * stride} raw bytes, got {len(raw)}')

filters = []
for y in range(h):
    f = raw[y * stride]
    filters.append(f)
unique = set(filters)
allowed = {0, 1}
unexpected = unique - allowed
if unexpected:
    raise SystemExit(f'unexpected filter byte(s) under -sub: {sorted(unexpected)} (full set {sorted(unique)})')
print(f'-sub filters OK, distribution={sorted(unique)}')
PY
