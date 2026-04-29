#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-getbbox
# @title: Pillow WebP getbbox
# @description: Opens a WebP fixture with Pillow and verifies getbbox returns a bounding box that fits within the source image dimensions.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-getbbox"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_ppm() {
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
}

make_webp() {
  make_ppm
  cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
}

make_webp
python3 - <<'PY' "$tmpdir/in.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    bbox = im.getbbox()
    assert bbox is not None
    assert bbox[2] - bbox[0] <= im.size[0]
    assert bbox[3] - bbox[1] <= im.size[1]
    print("bbox", bbox)
PY
