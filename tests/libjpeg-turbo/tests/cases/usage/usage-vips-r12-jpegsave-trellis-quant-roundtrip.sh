#!/usr/bin/env bash
# @testcase: usage-vips-r12-jpegsave-trellis-quant-roundtrip
# @title: vips jpegsave --trellis-quant produces a valid JPEG at the original size
# @description: Saves a JPEG via vips jpegsave with --trellis-quant (trellis quantisation enabled) and verifies the output is recognised by file(1) and reloads through vipsheader at the original geometry.
# @timeout: 60
# @tags: usage, jpeg, image, mozjpeg
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 40, 30
data = bytes([(((x * 13) ^ (y * 7)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/tq.jpg" --trellis-quant --Q 80

file "$tmpdir/tq.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader -a "$tmpdir/tq.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 40'
validator_assert_contains "$tmpdir/hdr" 'height: 30'
