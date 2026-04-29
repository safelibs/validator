#!/usr/bin/env bash
# @testcase: usage-python3-pil-thumbnail-webp
# @title: Pillow thumbnails WebP
# @description: Builds a thumbnail from WebP input with Pillow and verifies dimensions.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-thumbnail-webp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_webp() {
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
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

make_webp
python3 - <<'PY' "$tmpdir/in.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    im.thumbnail((2, 2))
    assert im.size[0] <= 2 and im.size[1] <= 2
    print("thumbnail", im.size)
PY
