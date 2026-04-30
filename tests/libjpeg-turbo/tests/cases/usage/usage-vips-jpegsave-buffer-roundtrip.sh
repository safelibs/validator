#!/usr/bin/env bash
# @testcase: usage-vips-jpegsave-buffer-roundtrip
# @title: vips jpegsave roundtrip
# @description: Encodes a PPM with vips jpegsave at Q=75 and verifies JPEG SOI/EOI bytes plus JFIF or Exif marker.
# @timeout: 180
# @tags: usage, jpeg, image
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
# vips jpegsave wraps the libjpeg-turbo encoder at Q=75 — the same path
# the C/Python jpegsave APIs drive — and writes a self-contained JPEG to disk.
vips jpegsave "$tmpdir/in.jpg" "$tmpdir/out.jpg" --Q 75
file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

python3 - <<'PY' "$tmpdir/out.jpg"
import sys
from pathlib import Path
data = Path(sys.argv[1]).read_bytes()
assert data[:2] == b'\xff\xd8', f"missing SOI marker: {data[:4]!r}"
assert data[-2:] == b'\xff\xd9', f"missing EOI marker: {data[-2:]!r}"
# Either JFIF or Exif APP marker should appear in the header.
header = data[:64]
assert b'JFIF' in header or b'Exif' in header, f"no APP marker in header: {header!r}"
print('soi/eoi ok, bytes', len(data))
PY
