#!/usr/bin/env bash
# @testcase: usage-pngquant-strip-verify-png
# @title: pngquant strip removes ancillary chunks
# @description: Runs pngquant with --strip and verifies that auxiliary text/time chunks are absent compared to a non-stripped run.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --force --strip --output "$tmpdir/stripped.png" 256 "$png"
pngquant --force --output "$tmpdir/kept.png" 256 "$png"

file "$tmpdir/stripped.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

python3 - "$tmpdir/stripped.png" "$tmpdir/kept.png" <<'PY'
import struct, sys

def chunks(path):
    with open(path, 'rb') as fh:
        data = fh.read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    out = []
    i = 8
    while i < len(data):
        length = struct.unpack('>I', data[i:i+4])[0]
        ctype = data[i+4:i+8].decode('ascii')
        out.append(ctype)
        i += 8 + length + 4
    return out

stripped = chunks(sys.argv[1])
print('stripped chunks:', stripped)
# Stripped output should not contain auxiliary text or time metadata.
for forbidden in ('tEXt', 'zTXt', 'iTXt', 'tIME'):
    assert forbidden not in stripped, (forbidden, stripped)
# Required chunks must remain.
for required in ('IHDR', 'IDAT', 'IEND'):
    assert required in stripped, (required, stripped)
PY
