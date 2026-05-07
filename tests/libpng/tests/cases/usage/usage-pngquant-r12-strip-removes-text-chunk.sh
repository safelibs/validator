#!/usr/bin/env bash
# @testcase: usage-pngquant-r12-strip-removes-text-chunk
# @title: pngquant --strip removes a tEXt chunk that was present in the source
# @description: Builds a PNG with a tEXt "Author Alice" chunk via pnmtopng -text, then quantises with --strip and verifies the output PNG no longer contains the "Author\x00Alice" tEXt payload, locking in that --strip drops ancillary chunks.
# @timeout: 180
# @tags: usage, image, png, strip
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 32, 32
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 8 & 0xff, y * 8 & 0xff, ((x + y) * 4) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

printf 'Author Alice\n' >"$tmpdir/text.txt"
pnmtopng -text "$tmpdir/text.txt" "$tmpdir/in.ppm" >"$tmpdir/in.png"

# Sanity: the source carries the tEXt chunk.
python3 - "$tmpdir/in.png" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert b'Author\x00Alice' in data, 'precondition: tEXt chunk missing in source'
PY

pngquant --strip --force --output "$tmpdir/out.png" 16 "$tmpdir/in.png"

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
assert b'Author\x00Alice' not in data, '--strip did not remove tEXt chunk'
PY
