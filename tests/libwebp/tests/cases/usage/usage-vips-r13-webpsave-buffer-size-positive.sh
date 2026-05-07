#!/usr/bin/env bash
# @testcase: usage-vips-r13-webpsave-buffer-size-positive
# @title: vips copy ... .webp[Q=70] writes a WebP file with positive byte length
# @description: Encodes a synthetic PPM through vips copy with a webp[] options suffix and verifies the output starts with the RIFF/WEBP magic and exceeds 24 bytes, exercising the parameterised webp output path used as a buffer-encode equivalent.
# @timeout: 180
# @tags: usage, vips, webp
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 40, 30
data = bytes([(((x * 9) ^ (y * 5)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips copy "$tmpdir/in.ppm" "$tmpdir/out.webp[Q=70]"
[[ -s "$tmpdir/out.webp" ]]

# Verify RIFF/WEBP magic header.
python3 - <<'PY' "$tmpdir/out.webp"
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:4] == b'RIFF', data[:4]
assert data[8:12] == b'WEBP', data[8:12]
assert len(data) > 24, f'buffer too small: {len(data)}'
PY

# And the byte stream is recognised as Web/P by file(1).
file "$tmpdir/out.webp" | grep -q 'Web/P'
