#!/usr/bin/env bash
# @testcase: usage-vips-r14-jpegsave-restart-interval-zero-no-dri
# @title: vips jpegsave --restart-interval 0 emits a JPEG without a DRI marker
# @description: Saves a JPEG via vips jpegsave with --restart-interval 0 (the default off-state) and confirms the resulting stream has no DRI (FFDD) marker, exercising the negative path for the restart-interval encoder option.
# @timeout: 180
# @tags: usage, jpeg, image, encoder
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 64, 48
data = bytes([(((x * 7) ^ (y * 5)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/no-rst.jpg" --restart-interval 0 --Q 80
file "$tmpdir/no-rst.jpg" | grep -q 'JPEG image data'

python3 - <<'PY' "$tmpdir/no-rst.jpg"
import sys
from pathlib import Path
data = Path(sys.argv[1]).read_bytes()
assert data[:2] == b'\xff\xd8' and data[-2:] == b'\xff\xd9', 'invalid JPEG'
assert b'\xff\xdd' not in data, 'unexpected DRI marker for restart-interval=0'
PY
