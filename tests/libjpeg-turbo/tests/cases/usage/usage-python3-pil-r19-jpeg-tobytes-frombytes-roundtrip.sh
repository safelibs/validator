#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-jpeg-tobytes-frombytes-roundtrip
# @title: Pillow JPEG decode then tobytes/frombytes reconstructs an identical RGB image
# @description: Saves a 32x16 RGB JPEG via Pillow at quality=95, reopens it, dumps the pixel bytes via tobytes(), reconstructs a fresh Image via Image.frombytes("RGB", size, data), and asserts the two images have identical pixel buffers and identical sizes, exercising libjpeg-turbo decode followed by Pillow's raw-byte round-trip without re-encoding.
# @timeout: 60
# @tags: usage, jpeg, python, tobytes, frombytes, r19
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
out = base / "rt.jpg"
W, H = 32, 16
src = Image.new("RGB", (W, H))
src.putdata([((x * 31) & 255, (y * 17) & 255, ((x + 3 * y)) & 255)
             for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=95)

with Image.open(out) as im:
    im.load()
    assert im.mode == "RGB", im.mode
    data = im.tobytes()
    rebuilt = Image.frombytes("RGB", im.size, data)
    assert rebuilt.size == im.size, (rebuilt.size, im.size)
    assert rebuilt.tobytes() == data, "tobytes/frombytes round-trip differs"
PY
