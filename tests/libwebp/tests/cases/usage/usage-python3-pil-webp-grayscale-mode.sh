#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-grayscale-mode
# @title: Pillow WebP grayscale mode
# @description: Converts a WebP fixture through Pillow grayscale L mode, saves as WebP, and verifies the reopened pixel has equal R, G, and B channels.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-grayscale-mode"
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
python3 - <<'PY' "$tmpdir/in.webp" "$tmpdir/gray.webp"
from PIL import Image
import sys
with Image.open(sys.argv[1]) as im:
    gray = im.convert("L").convert("RGB")
    gray.save(sys.argv[2], "WEBP", lossless=True)
with Image.open(sys.argv[2]) as reopened:
    reopened.load()
    pixel = reopened.getpixel((0, 0))
    assert pixel[0] == pixel[1] == pixel[2]
    print("gray", pixel)
PY
