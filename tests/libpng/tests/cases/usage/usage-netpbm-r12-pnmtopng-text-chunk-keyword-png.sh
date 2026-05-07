#!/usr/bin/env bash
# @testcase: usage-netpbm-r12-pnmtopng-text-chunk-keyword-png
# @title: netpbm pnmtopng -text inserts a tEXt chunk with the supplied keyword
# @description: Encodes a synthetic PPM with pnmtopng -text pointing at a small file that declares "Author Alice" and verifies the resulting PNG contains a tEXt chunk whose keyword "Author" and value "Alice" are present in the binary stream.
# @timeout: 120
# @tags: usage, png, netpbm, text-chunk
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 16, 16
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 16 & 0xff, y * 16 & 0xff, 128))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

# pnmtopng -text expects a file with "Keyword Value" lines.
printf 'Author Alice\n' >"$tmpdir/text.txt"

pnmtopng -text "$tmpdir/text.txt" "$tmpdir/in.ppm" >"$tmpdir/out.png"

python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
# tEXt chunks contain "keyword\x00value"
assert b'tEXt' in data, 'no tEXt chunk found'
assert b'Author\x00Alice' in data, 'expected Author\\x00Alice in tEXt chunk'
PY
