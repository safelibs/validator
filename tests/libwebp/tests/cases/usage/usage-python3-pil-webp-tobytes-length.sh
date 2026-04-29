#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-tobytes-length
# @title: Pillow WebP tobytes length
# @description: Opens a WebP fixture with Pillow, converts to RGB, and verifies tobytes returns width times height times three bytes.
# @timeout: 120
# @tags: usage
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-tobytes-length"
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
    data = im.convert("RGB").tobytes()
    assert len(data) == im.size[0] * im.size[1] * 3
    print("bytes", len(data))
PY
