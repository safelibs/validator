#!/usr/bin/env bash
# @testcase: usage-vips-r14-jpegsave-trellis-quant-flag-roundtrip
# @title: vips jpegsave --trellis-quant emits a valid JPEG at original geometry
# @description: Saves a JPEG via vips jpegsave with --trellis-quant (a mozjpeg-style trellis quantisation flag) and confirms the output is a syntactically valid JPEG with SOI/EOI markers and reloads at the input dimensions, exercising the trellis-quant encoder option.
# @timeout: 180
# @tags: usage, jpeg, image, mozjpeg
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 56, 40
data = bytes([(((x * 7) ^ (y * 13)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/tq.jpg" --trellis-quant --Q 80
file "$tmpdir/tq.jpg" | grep -q 'JPEG image data'

python3 - <<'PY' "$tmpdir/tq.jpg"
import sys
from pathlib import Path
data = Path(sys.argv[1]).read_bytes()
assert data[:2] == b'\xff\xd8' and data[-2:] == b'\xff\xd9', 'invalid JPEG'
PY

vipsheader -a "$tmpdir/tq.jpg" >"$tmpdir/hdr.txt"
validator_assert_contains "$tmpdir/hdr.txt" 'width: 56'
validator_assert_contains "$tmpdir/hdr.txt" 'height: 40'
