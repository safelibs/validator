#!/usr/bin/env bash
# @testcase: usage-pngquant-strip-text-chunk-verify-png
# @title: pngquant --strip removes tEXt chunk
# @description: Re-encodes basn2c08.png with an injected tEXt chunk via pnmtopng -text, runs pngquant --strip, and uses Python to walk the PNG chunk structure of the output and confirm no tEXt/zTXt/iTXt chunks remain while IHDR and IDAT do.
# @timeout: 180
# @tags: usage, image, png, metadata
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-strip-text-chunk-verify-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

# Build a PPM round-trip and re-encode with an injected tEXt chunk so we
# have a known ancillary chunk to strip. pnmtopng -text takes a text file
# whose entries are pairs of lines: keyword, then the payload text.
pngtopnm "$png" >"$tmpdir/in.ppm"
cat >"$tmpdir/text.txt" <<'TXT'
Comment
validator-strip-textchunk-K8M2
TXT
pnmtopng -text "$tmpdir/text.txt" "$tmpdir/in.ppm" >"$tmpdir/with_meta.png"
file "$tmpdir/with_meta.png" | tee "$tmpdir/file-in"
validator_assert_contains "$tmpdir/file-in" 'PNG image data'

# Sanity: walk the chunks of the input and confirm a tEXt chunk is present.
python3 - "$tmpdir/with_meta.png" require-text <<'PY'
import struct
import sys

path, mode = sys.argv[1], sys.argv[2]
data = open(path, 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
if not data.startswith(sig):
    raise SystemExit('not a PNG signature')
idx = len(sig)
chunks = []
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    chunks.append(ctype)
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
text_like = {'tEXt', 'zTXt', 'iTXt'}
present = text_like.intersection(chunks)
if mode == 'require-text':
    if not present:
        raise SystemExit(f'expected a text chunk in input, got {chunks}')
elif mode == 'forbid-text':
    if present:
        raise SystemExit(f'expected no text chunks after --strip, got {present}')
    if 'IHDR' not in chunks or 'IDAT' not in chunks:
        raise SystemExit(f'expected IHDR and IDAT in output, got {chunks}')
else:
    raise SystemExit(f'unknown mode {mode!r}')
PY

pngquant --strip --force --output "$tmpdir/out.png" 256 "$tmpdir/with_meta.png"
file "$tmpdir/out.png" | tee "$tmpdir/file-out"
validator_assert_contains "$tmpdir/file-out" 'PNG image data'

# Walk the chunks of the stripped output and confirm no text chunks remain
# while structural chunks survive.
python3 - "$tmpdir/out.png" forbid-text <<'PY'
import struct
import sys

path, mode = sys.argv[1], sys.argv[2]
data = open(path, 'rb').read()
sig = b'\x89PNG\r\n\x1a\n'
if not data.startswith(sig):
    raise SystemExit('not a PNG signature')
idx = len(sig)
chunks = []
while idx < len(data):
    (length,) = struct.unpack('>I', data[idx:idx + 4])
    ctype = data[idx + 4:idx + 8].decode('ascii')
    chunks.append(ctype)
    idx += 8 + length + 4
    if ctype == 'IEND':
        break
text_like = {'tEXt', 'zTXt', 'iTXt'}
present = text_like.intersection(chunks)
if present:
    raise SystemExit(f'expected no text chunks after --strip, got {present}')
if 'IHDR' not in chunks or 'IDAT' not in chunks:
    raise SystemExit(f'expected IHDR and IDAT in output, got {chunks}')
PY

# And the marker bytes must be gone from the raw stream.
if grep -aFq 'validator-strip-textchunk-K8M2' "$tmpdir/out.png"; then
  printf 'pngquant --strip left text marker in output\n' >&2
  exit 1
fi
