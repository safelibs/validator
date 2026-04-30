#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpegimageplugin-marker-jpeg
# @title: Pillow JpegImagePlugin.MARKER table inspection
# @description: Loads the JpegImagePlugin.MARKER table and verifies a JPEG's actual SOI/SOF/DQT/DHT/EOI marker bytes match the table's known marker IDs.
# @timeout: 120
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-jpegimageplugin-marker-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, JpegImagePlugin
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'

Image.new('RGB', (16, 16), (140, 140, 140)).save(source, 'JPEG', quality=90, subsampling=0)

# MARKER table: keys are 0xFFxx integers (e.g. 0xFFD8 SOI, 0xFFD9 EOI, 0xFFDB DQT,
# 0xFFC4 DHT, 0xFFC0 SOF0). Pillow stores them as full 16-bit integers.
markers = JpegImagePlugin.MARKER
assert isinstance(markers, dict)
assert 0xFFD8 in markers, 'SOI must be in MARKER table'
assert 0xFFD9 in markers, 'EOI must be in MARKER table'
assert 0xFFDB in markers, 'DQT must be in MARKER table'
assert 0xFFC4 in markers, 'DHT must be in MARKER table'
assert 0xFFC0 in markers, 'SOF0 must be in MARKER table'

soi_entry = markers[0xFFD8]
eoi_entry = markers[0xFFD9]
# Each entry is (name, description, handler) - validate basic shape.
assert isinstance(soi_entry, tuple) and len(soi_entry) >= 1, soi_entry
assert 'SOI' in soi_entry[0] or 'Start' in (soi_entry[1] if len(soi_entry) > 1 else ''), soi_entry

# Now scan the actual JPEG bytes and confirm every marker we encounter is in the table.
data = source.read_bytes()
assert data[:2] == b'\xff\xd8', data[:2]
assert data[-2:] == b'\xff\xd9', data[-2:]

seen = set()
i = 0
n = len(data)
while i < n - 1:
    if data[i] == 0xFF and data[i + 1] not in (0x00, 0xFF):
        marker = (0xFF << 8) | data[i + 1]
        if marker in markers:
            seen.add(marker)
        if marker == 0xFFD9:
            break
        # Skip to next marker via segment length where applicable.
        if marker in (0xFFD8, 0xFFD9) or 0xFFD0 <= marker <= 0xFFD7:
            i += 2
            continue
        if i + 4 > n:
            break
        seg_len = (data[i + 2] << 8) | data[i + 3]
        i += 2 + seg_len
        continue
    i += 1

required = {0xFFD8, 0xFFD9, 0xFFDB, 0xFFC4, 0xFFC0}
assert required.issubset(seen), (required - seen, seen)
print('marker', sorted(hex(m) for m in seen))

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.size == (16, 16)
    assert im.mode == 'RGB'
PYCASE

file "$tmpdir/in.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
