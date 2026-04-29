#!/usr/bin/env bash
# @testcase: usage-python3-pil-point-offset-jpeg
# @title: Pillow point offset JPEG
# @description: Applies a point-wise channel offset to a JPEG with Pillow and verifies the transformed image remains decodable.
# @timeout: 180
# @tags: usage, jpeg, image
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-point-offset-jpeg"
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

make_jpeg
python3 - <<'PY' "$tmpdir/in.jpg" "$tmpdir/out.jpg"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.point(lambda value: min(255, value + 10))
    out.save(sys.argv[2], "JPEG")
with Image.open(sys.argv[2]) as im:
    assert im.size == (4, 3)
    print("point", im.size)
PY
