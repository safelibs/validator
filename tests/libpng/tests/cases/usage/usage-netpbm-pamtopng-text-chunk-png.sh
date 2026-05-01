#!/usr/bin/env bash
# @testcase: usage-netpbm-pamtopng-text-chunk-png
# @title: netpbm pamtopng -text injects tEXt chunks
# @description: Builds a pamtopng text-keywords file with two entries, encodes basn2c08.png using pamtopng -text, walks the output to confirm at least two tEXt chunks were emitted, and greps the raw PNG bytes to confirm the keyword payload marker is preserved verbatim.
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

cat >"$tmpdir/text.txt" <<'TXT'
Title
pamtopng-text-validator-marker-Q5W7
Author
validator
TXT

pamtopng -text="$tmpdir/text.txt" "$tmpdir/in.ppm" >"$tmpdir/out.png"
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
text_count = 0
chunks = []
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    chunks.append(ctype)
    if ctype == 'tEXt':
        text_count += 1
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
if text_count < 2:
    raise SystemExit(f'expected >=2 tEXt chunks, got {text_count} ({chunks})')
if 'IHDR' not in chunks or 'IDAT' not in chunks:
    raise SystemExit(f'missing structural chunks: {chunks}')
print(f'tEXt OK, count={text_count}')
PY

if ! grep -aFq 'pamtopng-text-validator-marker-Q5W7' "$tmpdir/out.png"; then
  printf 'expected text marker preserved in PNG bytes\n' >&2
  exit 1
fi
