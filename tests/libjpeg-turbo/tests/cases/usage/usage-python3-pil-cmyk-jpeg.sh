#!/usr/bin/env bash
# @testcase: usage-python3-pil-cmyk-jpeg
# @title: Pillow handles CMYK JPEG
# @description: Writes and reopens a CMYK JPEG with Pillow.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-cmyk-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_jpeg() {
  python3 - <<'PY' "$tmpdir/in.ppm"
from pathlib import Path
import sys
pixels = bytes([
    255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0,
    255, 0, 255, 0, 255, 255, 40, 40, 40, 220, 220, 220,
    100, 20, 30, 20, 100, 30, 20, 30, 100, 200, 120, 20,
])
Path(sys.argv[1]).write_bytes(b"P6\n4 3\n255\n" + pixels)
PY
  cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
}

python3 - <<'PY' "$tmpdir/cmyk.jpg"
from PIL import Image
import sys
im = Image.new("CMYK", (3, 2), (0, 128, 128, 0))
im.save(sys.argv[1], "JPEG")
with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    assert reopened.mode == "CMYK", reopened.mode
    print("cmyk", reopened.size, reopened.mode)
PY
