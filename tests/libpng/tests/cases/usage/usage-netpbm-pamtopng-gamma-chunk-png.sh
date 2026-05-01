#!/usr/bin/env bash
# @testcase: usage-netpbm-pamtopng-gamma-chunk-png
# @title: netpbm pamtopng -gamma emits gAMA chunk
# @description: Re-encodes basn2c08.png with pamtopng -gamma=0.45 and confirms the resulting PNG carries a 4-byte gAMA chunk whose big-endian value is 45000 (gamma * 100000), distinguishing the gAMA-bearing output from a default pamtopng encoding which omits gAMA.
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

# Default encode (no -gamma): must NOT carry a gAMA chunk.
pamtopng "$tmpdir/in.ppm" >"$tmpdir/plain.png"
# With -gamma=0.45: MUST carry a gAMA chunk with value 45000.
pamtopng -gamma=0.45 "$tmpdir/in.ppm" >"$tmpdir/gamma.png"

file "$tmpdir/plain.png" | tee "$tmpdir/plain.file"
validator_assert_contains "$tmpdir/plain.file" 'PNG image data'
file "$tmpdir/gamma.png" | tee "$tmpdir/gamma.file"
validator_assert_contains "$tmpdir/gamma.file" 'PNG image data'

python3 - "$tmpdir/plain.png" "$tmpdir/gamma.png" <<'PY'
import struct
import sys


def walk(path):
    data = open(path, 'rb').read()
    sig = b'\x89PNG\r\n\x1a\n'
    if not data.startswith(sig):
        raise SystemExit(f'not a PNG signature: {path}')
    idx = len(sig)
    chunks = []
    gAMA_value = None
    while idx < len(data):
        (length,) = struct.unpack('>I', data[idx:idx + 4])
        ctype = data[idx + 4:idx + 8].decode('ascii')
        chunks.append(ctype)
        if ctype == 'gAMA':
            if length != 4:
                raise SystemExit(f'gAMA must be 4 bytes, got {length}')
            (gAMA_value,) = struct.unpack('>I', data[idx + 8:idx + 12])
        idx += 8 + length + 4
        if ctype == 'IEND':
            break
    return chunks, gAMA_value


plain_chunks, plain_g = walk(sys.argv[1])
gamma_chunks, gamma_g = walk(sys.argv[2])
if 'gAMA' in plain_chunks:
    raise SystemExit(f'unexpected gAMA in default-pamtopng output: {plain_chunks}')
if 'gAMA' not in gamma_chunks:
    raise SystemExit(f'expected gAMA in -gamma=0.45 output: {gamma_chunks}')
if gamma_g != 45000:
    raise SystemExit(f'expected gAMA payload 45000, got {gamma_g}')
print(f'gAMA chunk OK, value={gamma_g}')
PY
