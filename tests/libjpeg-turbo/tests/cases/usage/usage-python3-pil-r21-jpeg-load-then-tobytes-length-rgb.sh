#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-jpeg-load-then-tobytes-length-rgb
# @title: Pillow Image.tobytes after JPEG decode returns exactly W*H*3 bytes for RGB
# @description: Encodes a 50x30 RGB image as JPEG, re-opens it via Pillow, calls tobytes() on the decoded image and asserts the resulting byte string length equals 50*30*3 = 4500 - locking in libjpeg-turbo's full-decode raw byte output length matching the expected 3-byte-per-pixel packed RGB layout.
# @timeout: 120
# @tags: usage, jpeg, python, tobytes, raw, r21
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
out = base / "rgb.jpg"
W, H = 50, 30
src = Image.new("RGB", (W, H))
src.putdata([((x * 9) & 255, (y * 17) & 255, ((x ^ y) * 5) & 255)
             for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=90)

with Image.open(out) as im:
    im.load()
    assert im.mode == "RGB", im.mode
    data = im.tobytes()
    assert len(data) == W * H * 3, ("expected", W * H * 3, "got", len(data))
PY
