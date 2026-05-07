#!/usr/bin/env bash
# @testcase: usage-vips-r13-jpegsave-quant-table-zero-roundtrip
# @title: vips jpegsave --quant-table 0 emits a valid JPEG at the source size
# @description: Saves a JPEG via vips jpegsave with --quant-table 0 (the standard JPEG annex-K table set) and verifies the output is recognised as a JPEG with the original geometry, exercising the named-quant-table selector path.
# @timeout: 60
# @tags: usage, jpeg, image, quant-table
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 40, 32
data = bytes([(((x * 7) + (y * 13)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/q.jpg" --quant-table 0 --Q 80

file "$tmpdir/q.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader -a "$tmpdir/q.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 40'
validator_assert_contains "$tmpdir/hdr" 'height: 32'
