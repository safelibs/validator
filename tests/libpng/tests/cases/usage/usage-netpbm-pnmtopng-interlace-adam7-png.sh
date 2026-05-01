#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmtopng-interlace-adam7-png
# @title: netpbm pnmtopng -interlace Adam7
# @description: Re-encodes basn2c08.png with pnmtopng -interlace, parses the IHDR chunk to confirm the interlace method byte equals 1 (Adam7), and verifies the interlaced output decodes to pixels identical to the non-interlaced re-encode.
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
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/plain.png"
pnmtopng -interlace "$tmpdir/in.ppm" >"$tmpdir/adam7.png"
file "$tmpdir/adam7.png" | tee "$tmpdir/adam7.file"
validator_assert_contains "$tmpdir/adam7.file" 'PNG image data'
file "$tmpdir/plain.png" | tee "$tmpdir/plain.file"
validator_assert_contains "$tmpdir/plain.file" 'PNG image data'

python3 - "$tmpdir/adam7.png" "$tmpdir/plain.png" <<'PY'
import struct
import sys

def ihdr(path):
    data = open(path, 'rb').read()
    sig = b'\x89PNG\r\n\x1a\n'
    assert data.startswith(sig)
    idx = len(sig)
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8]
    if ctype != b'IHDR':
        raise SystemExit(f'expected IHDR first, got {ctype!r}')
    payload = data[idx + 8:idx + 8 + length]
    return struct.unpack('>IIBBBBB', payload)

a = ihdr(sys.argv[1])
p = ihdr(sys.argv[2])
if a[6] != 1:
    raise SystemExit(f'expected interlace=1 for adam7 output, got {a[6]}')
if p[6] != 0:
    raise SystemExit(f'expected interlace=0 for plain output, got {p[6]}')
PY

pngtopnm "$tmpdir/adam7.png" >"$tmpdir/adam7.ppm"
pngtopnm "$tmpdir/plain.png" >"$tmpdir/plain.ppm"
cmp "$tmpdir/adam7.ppm" "$tmpdir/plain.ppm"
cmp "$tmpdir/adam7.ppm" "$tmpdir/in.ppm"
