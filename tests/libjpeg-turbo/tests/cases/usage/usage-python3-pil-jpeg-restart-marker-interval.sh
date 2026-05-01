#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-restart-marker-interval
# @title: Pillow JPEG restart marker interval
# @description: Saves a JPEG with restart_marker=8 via Pillow and verifies an RST/DRI structure is encoded by scanning the byte stream for 0xFFDD or 0xFFD0-D7.
# @timeout: 180
# @tags: usage, jpeg, python, encoder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

tmpdir = Path(sys.argv[1])
src = Image.new('RGB', (96, 64))
src.putdata([(((x * 7) ^ (y * 5)) & 255, (x + y) & 255, (x * y) & 255)
             for y in range(64) for x in range(96)])

out = tmpdir / 'rst.jpg'
src.save(out, 'JPEG', quality=80, restart_marker_blocks=8)
data = out.read_bytes()
assert data[:2] == b'\xff\xd8', 'not a JPEG'

# DRI marker is FFDD; if present, an interval was set. Restart markers
# FFD0-FFD7 should also appear in the entropy-coded segment.
has_dri = b'\xff\xdd' in data
has_rst = any(bytes((0xff, 0xd0 + n)) in data for n in range(8))
assert has_dri or has_rst, 'no restart structures found in encoded JPEG'
print('restart structures present', has_dri, has_rst)
PYCASE

file "$tmpdir/rst.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
