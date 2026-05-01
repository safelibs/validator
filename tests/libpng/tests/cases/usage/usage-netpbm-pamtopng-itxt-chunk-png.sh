#!/usr/bin/env bash
# @testcase: usage-netpbm-pamtopng-itxt-chunk-png
# @title: netpbm pamtopng -itxt injects iTXt chunk
# @description: Encodes basn2c08.png with pamtopng -itxt pointing at an international-text descriptor file, walks the output PNG chunk stream to confirm at least one iTXt chunk is present alongside structural IHDR/IDAT, and confirms the marker payload survives unmodified in the raw bytes.
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

# pamtopng -itxt expects a 4-line entry: keyword, language, translated keyword, text.
cat >"$tmpdir/itxt.txt" <<'TXT'
Comment
en
en
pamtopng-itxt-validator-marker-J4F2
TXT

pamtopng -itxt="$tmpdir/itxt.txt" "$tmpdir/in.ppm" >"$tmpdir/out.png"
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
itxt_count = 0
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    chunks.append(ctype)
    if ctype == 'iTXt':
        itxt_count += 1
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if itxt_count < 1:
    raise SystemExit(f'expected >=1 iTXt chunk, got {chunks}')
if 'IHDR' not in chunks or 'IDAT' not in chunks:
    raise SystemExit(f'missing structural chunks: {chunks}')
print(f'iTXt OK, count={itxt_count}')
PY

if ! grep -aFq 'pamtopng-itxt-validator-marker-J4F2' "$tmpdir/out.png"; then
  printf 'expected itxt marker preserved in PNG bytes\n' >&2
  exit 1
fi
