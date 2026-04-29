#!/usr/bin/env bash
# @testcase: usage-python3-pil-point-offset-webp
# @title: Pillow point offset WebP
# @description: Applies a point-wise channel offset to a WebP image with Pillow and verifies the transformed output remains decodable.
# @timeout: 180
# @tags: usage, webp, image
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-point-offset-webp"
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
python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/out.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    out = im.point(lambda value: min(255, value + 15))
    out.save(sys.argv[2], "WEBP")
with Image.open(sys.argv[2]) as im:
    assert im.size == (4, 3)
    print("point", im.size)
PY
