#!/usr/bin/env bash
# @testcase: usage-vips-r16-copy-jpeg-jpeg-preserves-dims
# @title: vips copy from JPEG to JPEG preserves width and height
# @description: Encodes a 56x40 PPM via vips jpegsave, then runs vips copy from JPEG to JPEG and asserts the output is JPEG-typed with vipsheader reporting the same width and height as the input, exercising libjpeg-turbo's decode-encode round-trip through vips copy without geometry changes.
# @timeout: 180
# @tags: usage, vips, jpeg, copy
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 56, 40
data = bytes([(((x * 17) ^ (y * 23)) & 0xff)
              for y in range(H) for x in range(W * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips copy "$tmpdir/in.jpg" "$tmpdir/out.jpg"

file "$tmpdir/out.jpg" | grep -q 'JPEG image data'
vipsheader -a "$tmpdir/out.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 56'
validator_assert_contains "$tmpdir/hdr" 'height: 40'
