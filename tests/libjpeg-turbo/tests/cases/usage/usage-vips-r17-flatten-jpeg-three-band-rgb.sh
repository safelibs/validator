#!/usr/bin/env bash
# @testcase: usage-vips-r17-flatten-jpeg-three-band-rgb
# @title: vips flatten on a JPEG yields a 3-band RGB image with no alpha
# @description: Encodes a 24x16 RGB PPM as JPEG then runs vips flatten (which composites alpha against a background) and asserts the output is a 3-band image with the original dimensions reported by vipsheader, exercising libjpeg-turbo decode followed by vips flatten on an alpha-less source (the alpha-less input is a no-op for flatten, leaving 3 bands).
# @timeout: 180
# @tags: usage, vips, jpeg, flatten
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 24, 16
data = bytes([(((x * 11) ^ (y * 17)) & 0xff)
              for y in range(H) for x in range(W * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips flatten "$tmpdir/in.jpg" "$tmpdir/out.v"

vipsheader "$tmpdir/out.v" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" '24x16'
validator_assert_contains "$tmpdir/hdr" '3 bands'
