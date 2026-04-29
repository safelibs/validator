#!/usr/bin/env bash
# @testcase: usage-python3-pil-memory-open-webp
# @title: Pillow opens WebP from memory
# @description: Loads a WebP image from an in-memory byte buffer with Pillow and verifies the decoded dimensions.
# @timeout: 180
# @tags: usage, webp, image
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-memory-open-webp"
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
from io import BytesIO
from pathlib import Path
from PIL import Image
import sys
payload = Path(sys.argv[1]).read_bytes()
with Image.open(BytesIO(payload)) as im:
    im.load()
    assert im.size == (4, 3)
    print("memory", im.size)
PY
