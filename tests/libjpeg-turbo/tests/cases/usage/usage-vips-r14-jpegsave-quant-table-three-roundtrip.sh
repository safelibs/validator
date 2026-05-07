#!/usr/bin/env bash
# @testcase: usage-vips-r14-jpegsave-quant-table-three-roundtrip
# @title: vips jpegsave --quant-table 3 emits a JPEG carrying a DQT marker
# @description: Saves a JPEG via vips jpegsave with --quant-table 3 (a non-default named table) and confirms the output contains a DQT (FFDB) marker plus reloads at the original geometry, exercising the named-quant-table encoder selector.
# @timeout: 180
# @tags: usage, jpeg, image, quant-table
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 48, 36
data = bytes([(((x * 9) + (y * 11)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/qt3.jpg" --quant-table 3 --Q 80
file "$tmpdir/qt3.jpg" | grep -q 'JPEG image data'

python3 - <<'PY' "$tmpdir/qt3.jpg"
import sys
from pathlib import Path
data = Path(sys.argv[1]).read_bytes()
assert data[:2] == b'\xff\xd8' and data[-2:] == b'\xff\xd9', 'invalid JPEG'
assert b'\xff\xdb' in data, 'missing DQT marker'
PY

vipsheader -a "$tmpdir/qt3.jpg" >"$tmpdir/hdr.txt"
validator_assert_contains "$tmpdir/hdr.txt" 'width: 48'
validator_assert_contains "$tmpdir/hdr.txt" 'height: 36'
